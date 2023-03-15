# Wrapper for whatever linear programming we need, in case we don't want to
# use JuMP (e.g., for latency reasons).

module LP

import JuMP
using JuMP: @variable, @objective, @constraint
using MathOptInterface: OPTIMAL
using HiGHS

mutable struct Model
    LP          :: JuMP.Model
    vars
    base
    shape
    maxval
end
function Model(shape)

    P = JuMP.Model(HiGHS.Optimizer)
    JuMP.set_silent(P)

    Y = shape
    n = length(Y)

    @variable(P, x[i=1:n, j=1:Y[i]] >= 0)

    @variable(P, z >= 0)
    @constraint(P, z == sum(x[i, Y[i]] for i=1:n))

    @objective(P, Min, sum(x))

    @constraint(P, [i=1:n, j=1:Y[i]-1], x[i,j] + 1 ≤ x[i,j+1])

    Model(P, x, [], Y, z)

end

set_base!(m::Model, idx) = (m.base = idx)
get_base(m::Model) = m.base

optimize!(m::Model) = JuMP.optimize!(m.LP)

function maybe(func!::Function, m::Model)
    cons = func!(m)
    optimize!(m)
    status = JuMP.termination_status(m.LP)
    for con in cons
        JuMP.delete(m.LP, con)
    end
    return status == OPTIMAL
end

maybe_lt(m::Model, lhs, rhs) = maybe(m->lt!(m, lhs, rhs), m)
maybe_gt(m::Model, lhs, rhs) = maybe(m->gt!(m, lhs, rhs), m)

vars(m::Model, idx) = [m.vars[i, j] for (i,j) in zip(m.base, idx)]

lhs_minus_rhs(m::Model, lhs, rhs) = sum(vars(m, lhs)) - sum(vars(m, rhs))

gt!(m::Model, lhs, rhs) = [@constraint(m.LP, lhs_minus_rhs(m, lhs, rhs) ≥ 1)]
lt!(m::Model, lhs, rhs) = gt!(m, rhs, lhs)
eq!(m::Model, lhs, rhs) = [@constraint(m.LP, lhs_minus_rhs(m, lhs, rhs) == 0)]

value(m::Model, i, j) = JuMP.value(m.vars[i, j])

fix(m::Model, i, j, v) = JuMP.fix(m.vars[i, j], v; force = true)
fixtotal(m::Model, v) = JuMP.fix(m.maxval, v; force = true)

end
