@kwdef struct Unfurled
    body
    ndims
    arr
    Unfurled(body, ndims, arr) = new(body, ndims, arr) 
    Unfurled(body::Nothing, ndims, arr) = error()
end

Base.show(io::IO, ex::Unfurled) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Unfurled)
    print(io, "Unfurled(")
    print(io, ex.body)
    print(io, ", ")
    print(io, ex.ndims)
    print(io, ", ")
    print(io, ex.arr)
    print(io, ")")
end

FinchNotation.finch_leaf(x::Unfurled) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Unfurled) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::Unfurled)
    stylize_access(node, ctx, tns.body)
end

truncate(node::Unfurled, ctx, ext, ext_2) = Unfurled(truncate(node.body, ctx, ext, ext_2), node.ndims, node.arr)

function popdim(node::Unfurled)
    if node.ndims == 1
        return node.body
    else
        return Unfurled(node.body, node.ndims - 1, node.arr)
    end
end

function get_point_body(node::Unfurled, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(body_2, node.ndims, node.arr))
    end
end

get_reader(tns::Unfurled, ctx::LowerJulia, protos...) = tns
get_updater(tns::Unfurled, ctx::LowerJulia, protos...) = tns

(ctx::ThunkVisitor)(node::Unfurled) = Unfurled(ctx(node.body), node.ndims, node.arr)

function get_run_body(node::Unfurled, ctx, ext)
    body_2 = get_run_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(body_2, node.ndims, node.arr))
    end
end

function get_acceptrun_body(node::Unfurled, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(Unfurled(body_2, node.ndims, node.arr))
    end
end

function (ctx::PipelineVisitor)(node::Unfurled)
    map(ctx(node.body)) do (keys, body)
        return keys => Unfurled(body, node.ndims, node.arr)
    end
end

phase_body(node::Unfurled, ctx, ext, ext_2) = Unfurled(phase_body(node.body, ctx, ext, ext_2), node.ndims, node.arr)
phase_range(node::Unfurled, ctx, ext) = phase_range(node.body, ctx, ext)

get_spike_body(node::Unfurled, ctx, ext, ext_2) = Unfurled(get_spike_body(node.body, ctx, ext, ext_2), node.ndims, node.arr)
get_spike_tail(node::Unfurled, ctx, ext, ext_2) = popdim(Unfurled(get_spike_tail(node.body, ctx, ext, ext_2), node.ndims, node.arr))

visit_fill(node, tns::Unfurled) = visit_fill(node, tns.body)
visit_simplify(node::Unfurled) = Unfurled(visit_simplify(node.body), node.ndims, node.arr)

(ctx::SwitchVisitor)(node::Unfurled) = map(ctx(node.body)) do (guard, body)
    guard => Unfurled(body, node.ndims, node.arr)
end

function unfurl_access(node, ctx, eldim, tns::Unfurled)
    unfurl_access(node, ctx, eldim, tns.body)
end

function select_access(node, ctx::Finch.SelectVisitor, tns::Unfurled)
    select_access(node, ctx, tns.body)
end

(ctx::CycleVisitor)(node::Unfurled) = Unfurled(ctx(node.body), node.ndims, node.arr)

function lower(node::Unfurled, ctx::AbstractCompiler, ::DefaultStyle)
    error(node)
    ctx(node.body)
end

function get_furl_root_access(idx, tns::Unfurled)
    get_furl_root_access(idx, tns.body)
end
