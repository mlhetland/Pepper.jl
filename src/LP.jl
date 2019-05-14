# Wrapper for whatever linear programming we need, in case we don't want to
# use JuMP (e.g., for latency reasons).

module LP

import JuMP
using JuMP: @variable, @objective, @constraint
using MathOptInterface: OPTIMAL
using Clp

mutable struct Model
    LP          :: JuMP.Model
    vars
    base
end
function Model(shape)

    P = JuMP.Model(JuMP.with_optimizer(Clp.Optimizer, LogLevel = 0))
    Y = shape
    n = length(Y)

    @variable(P, x[i=1:n, j=1:Y[i]] >= 0)
    @objective(P, Min, sum(x))
    @constraint(P, [i=1:n, j=1:Y[i]-1], x[i,j] + 1 ≤ x[i,j+1])

    Model(P, x, [])

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

end
