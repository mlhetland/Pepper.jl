struct System
    criteria        :: Vector{String}
    levels          :: Vector{Vector{String}}
    points          :: Dict{Pair{String,String},Int}
end
System(criteria, levels) = System(criteria, levels, Dict())
System() = System([], [])

criteria(s::System) = s.criteria
levels(s::System) = s.levels

shape(s::System) = length.(levels(s))

function addcriterion(s::System, c)
    push!(criteria(s), c)
    push!(levels(s), [])
end

addlevel(s::System, l) = push!(last(levels(s)), l)

setpts(s::System, key, pts) = (s.points[key] = pts)
getpts(s::System, key) = get(s.points, key, nothing)

_key(s, i, j) = criteria(s)[i] => levels(s)[i][j]

setpts(s::System, i, j, pts) = setpts(s, _key(s, i, j), pts)
getpts(s::System, i, j) = getpts(s, _key(s, i, j))
