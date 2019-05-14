using DataStructures
import IterTools: subsets
import Base.Iterators: product

function rank!(oracle::Function, P, scores, lhs, rhs)

    # If one direction is impossible, they are implicitly ranked already:
    (LP.maybe_lt(P, lhs, rhs) && LP.maybe_gt(P, lhs, rhs)) || return

    # Otherwise, consult the oracle:
    choice = oracle(scores, LP.get_base(P), lhs, rhs)
    [LP.eq!, LP.gt!, LP.lt!][choice](P, lhs, rhs)

end

function lhs_iter(crit, bits)

    start = bits .+ 1
    stop = crit .+ bits .- 1

    product((:).(start, stop)...)

end

function rhs_iter(crit, bits, lhs)

    down = bits .== 1

    step = ones(Int, size(bits))
    step[down] .= -1

    start = lhs .+ step

    stop = copy(crit)
    stop[down] .= 1

    product((:).(start, step, stop)...)

end

function paprika(oracle::Function, scores; maxdegree=2)

    Y = shape(scores); P = LP.Model(Y); n = length(Y)

    for degree = 2:min(maxdegree, n), base in subsets(1:n, degree)

        LP.set_base!(P, base)

        crit = Y[base]

        for i = 1 : 2^degree - 1

            bits = digits(i, base=2, pad=degree)

            for lhs in lhs_iter(crit, bits), rhs in rhs_iter(crit, bits, lhs)

                rank!(oracle, P, scores, lhs, rhs)

            end

        end

    end

    LP.optimize!(P)

    for i = 1:n, j = 1:Y[i]
        setpts(scores, i, j, Int(round(LP.value(P, i, j))))
    end

end
