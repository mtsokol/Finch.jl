"""
Parallelism analysis plan: We will allow automatic paralleization when the following conditions are meet:
All non-locally defined tensors that are written, are only written to with the plain index i in a injective and consistent way and with an associative operator.

all reader or updater accesses on i need to be concurrent (safe to iterate multiple instances of at the same time)

two array axis properties: is_concurrent and is_injective
third properties: is_atomic

You aren't allowed to update a tensor without accessing it with i or marking atomic.

new array: make_atomic
"""

function gatherAcceses(prog) :: Vector{FinchNode}
    ret:: Vector{FinchNode} = []
    for node in PostOrderDFS(prog)
        if @capture node access(~tns, ~mode, ~idxs...)
            push!(ret, node)
        else
            continue
        end
    end
    return ret
end

function gatherAssignments(prog) :: Vector{FinchNode}
    ret:: Vector{FinchNode} = []
    for node in PostOrderDFS(prog)
        if @capture node assign(~lhs, ~op, ~rhs)
            push!(ret, node)
        else
            continue
        end
    end
    return ret
end

function gatherLocalDeclerations(prog) :: Vector{FinchNode}
    ret:: Vector{FinchNode} = []
    for node in PostOrderDFS(prog)
        if @capture node declare(~tns, ~init)
            push!(ret, tns)
        else
            continue
        end
    end
    return ret
end


struct ParallelAnalysisResults
    naive:: bool
    withAtomics:: bool
    withAtomicsAndAssoc:: bool
    tensorsNeedingAtomics:: Vector{FinchNode}
    nonAssocAssigns:: Vector{FinchNode}
    nonConCurrentAccss::Vector{FinchNode}
end

function parallelAnalysis(prog) :: ParallelAnalysisResults
    accs = gatherAcceses(prog)
    assigns = gatherAssignments(prog)
    locDefs = gatherLocalDeclerations(prog)

    # Step 0:Filter out local defs
    # Run through accs to check properties.

    # Step 1: Gather all the assigns and group them per root
    # Step 2: For each group, ensure they are all accessed via a plain i and using the same part of the tensor - (i.e the virtuals are identical) -  if not, add the root to the group needing atomics.
    # Step 3: Similarly, for associativity
    # Step 4: Look through all accesses and make sure they are concurrent. 

    return ParallelAnalysisResults(false, false, false, [], [], [])
end



#=
# willow says hello!
for node in PostOrderDFS(prgm)
    if @capture node access(~tns, ~mode, ~idxs..., i)
    if @capture node access(~tns, ~mode, ~idxs...)
=#
