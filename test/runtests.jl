using Test

using Pepper
import Pepper.CLI

let

    n = rand(3:8)
    cra = ["criterion-$i" for i=1:n]
    lvs = [["level-$i-$j" for j=1:rand(2:5)] for i=1:n]

    s1 = Pepper.System(cra, lvs)
    s2 = Pepper.System(cra, lvs)

    pts = [sort([rand(Int) for i in lv]) for lv in lvs]

    for i = 1:n, j = 1:length(pts[i])
        Pepper.setpts(s1, i, j, pts[i][j])
    end

    k = 2

    function oracle(_, base_idx, lhs, rhs)
        score1 = sum(Pepper.getpts(s1, i, j) for (i, j) in zip(base_idx, lhs))
        score2 = sum(Pepper.getpts(s1, i, j) for (i, j) in zip(base_idx, rhs))
        if score1 == score2
            return 1
        elseif score1 > score2
            return 2
        else
            return 3
        end
    end

    Pepper.paprika(oracle, s2, maxdegree=k)

end

let
    lines = split("""
    Cyanaurate:
        - mataeologue
        - neoclassicism
        - preponder
        - refractility
    Microwave:
        - polygrammatic
        - sugary
        - unpictorial
    Nonvariant:
        - telharmony
        - luteway
    Planeticose:
        - telharmony
        - luteway
    Archil:
        - facilitation
        - hairlock
        - anvilsmith
        - soursop
    """, "\n")
    s = Pepper.System()
    CLI.parse(lines, s)
    cases = []
    Pepper.paprika(s, maxdegree=3) do s, base_idx, lhs, rhs
        choice = rand(1:3)
        push!(cases, [base_idx, lhs, rhs, choice])
        choice
    end
    for case in cases
        base_idx, lhs, rhs, choice = case
        score1 = sum(Pepper.getpts(s, i, j) for (i, j) in zip(base_idx, lhs))
        score2 = sum(Pepper.getpts(s, i, j) for (i, j) in zip(base_idx, rhs))
        if choice == 1
            @test score1 == score2
        else
            if choice == 2
                score1, score2 = score2, score1
            end
            @test score1 < score2
        end
    end
end

let
    lines = split("""
    Cyanaurate:
        - mataeologue
        - neoclassicism
        - refractility
    Microwave:
        - polygrammatic
        - sugary
        - unpictorial: 5
    """, "\n")
    s = Pepper.System()
    CLI.parse(lines, s)

    # Pepper.setpts(s, "Microwave" => "unpictorial", 5)

    cases = []
    Pepper.paprika(s, total=100) do s, base_idx, lhs, rhs
        choice = rand(1:2)
        push!(cases, [base_idx, lhs, rhs, choice])
        choice
    end

    Y = Pepper.shape(s)
    n = length(Y)

    @test sum(Pepper.getpts(s, i, Y[i]) for i = 1:n) == 100
    @test Pepper.getpts(s, "Microwave" => "unpictorial") == 5
end
