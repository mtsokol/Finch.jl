```@meta
EditURL = "<unknown>/docs/src/benchmark.jl"
```

# Benchmarking

Julia code is [nototoriously
fussy](https://github.com/JuliaCI/BenchmarkTools.jl#why-does-this-package-exist)
to benchmark.
We'll use [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl)
to automatically follow best practices for getting reliable julia benchmarks. We'll also
follow the [Julia Performance Tips](https://docs.julialang.org/en/v1/manual/performance-tips/).

Finch is even trickier to benchmark, for a few reasons:
1. The first time an @finch function is called, it is compiled, which takes an
   extra long time. @finch can also incur dynamic dispatch costs if the array
   types are not [type
   stable](https://docs.julialang.org/en/v1/manual/faq/#man-type-stability). We
   can remedy this by using [`@finch_kernel`](@ref), which simplifies
   benchmarking by compiling the function ahead of time, so it behaves like a
   normal Julia function. If you must use `@finch`, try to ensure that the code
   is type-stable.
2. Finch fibers reuse memory from previous calls, so the first time a fiber is
   used in a finch function, it will allocate memory, but subsequent times not so
   much. If we want to benchmark the memory allocation, we can reconstruct the
   fiber each time. Otherwise, we can let the repeated executions of the kernel
   measure the non-allocating runtime.
3. Runtime for sparse code often depends on the sparsity pattern, so it's
   important to benchmark with representative data. Using standard matrices or tensors from
   [MatrixDepot.jl](https://github.com/JuliaLinearAlgebra/MatrixDepot.jl) or
   [TensorDepot.jl](https://github.com/willow-ahrens/TensorDepot.jl) is a good
   way to do this.

````julia
using Finch
using BenchmarkTools
using SparseArrays
using MatrixDepot
````

````
[ Info: verify download of index files...
[ Info: reading database
[ Info: adding metadata...
[ Info: adding svd data...
[ Info: writing database
[ Info: used remote sites are sparse.tamu.edu with MAT index and math.nist.gov with HTML index

````

Load a sparse matrix from MatrixDepot.jl and convert it to a Finch fiber

````julia
A = @fiber(d(sl(e(0.0))), matrixdepot("HB/west0067"))
(m, n) = size(A)

x = @fiber(d(e(0.0)), rand(n))
y = @fiber(d(e(0.0)))
````

````
Dense [1:0]
````

Construct a Finch kernel for sparse matrix-vector multiply

````julia
eval(@finch_kernel function spmv(y, A, x)
    y .= 0
    for j = _, i = _
        y[i] += A[i, j] * x[j]
    end
end)
````

````
spmv (generic function with 1 method)
````

Benchmark the kernel, ignoring allocation costs for y

````julia
@benchmark spmv($y, $A, $x)
````

````
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  41.208 μs … 964.083 μs  ┊ GC (min … max): 0.00% … 93.05%
 Time  (median):     45.375 μs               ┊ GC (median):    0.00%
 Time  (mean ± σ):   46.132 μs ±  17.338 μs  ┊ GC (mean ± σ):  0.71% ±  1.81%

  ▁▅▆▅▄▂▂▂ ▂▁  ▁▃███▆▅▃▄▃▁▂▁▁ ▁▃▃▂▂▂▂▃▃▃▂▂▁        ▁           ▂
  ████████████▇█████████████████████████████▇▇▇▇▇▇███▇▇████▇▇▇ █
  41.2 μs       Histogram: log(frequency) by time      55.9 μs <

 Memory estimate: 22.97 KiB, allocs estimate: 1470.
````

The `@benchmark` macro will benchmark a function in local scope, and it will run
the function a few times to estimate the runtime. It will also try to avoid
first-time compilation costs by running the function once before benchmarking
it. Note the use of `$` to interpolate the arrays into the benchmark, bringing
them into the local scope.

We can also benchmark the memory allocation of the kernel by constructing `y` in the
benchmark kernel

````julia
@benchmark begin
    y = @fiber(d(e(0.0)))
    y = spmv(y, $A, $x).y
end
````

````
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  42.583 μs …  1.025 ms  ┊ GC (min … max): 0.00% … 93.24%
 Time  (median):     46.667 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   47.711 μs ± 19.655 μs  ┊ GC (mean ± σ):  0.89% ±  2.08%

  ▃▅▅▄▂ ▁▁▂▁▃▁ ▇█▆▆▄▂▄▂▂▃▃▂▂▂▂▂▃▃▂▁▁                          ▂
  ████████████▇████████████████████████▇▇▇█████▇▇▇█▇▇▇▅▆▄▄▆▄▆ █
  42.6 μs      Histogram: log(frequency) by time        59 μs <

 Memory estimate: 23.56 KiB, allocs estimate: 1472.
````
