# Command-line interface for Pepper.jl

module CLI

using DocOpt, REPL.TerminalMenus
using Pepper

import Base: show

const doc = """
Usage:
    pepper [options] <criteria>

Options:
    -h, --help          Show this screen
    -d, --degree=<num>  Maximum number of criteria per question [default: 2]
    -t, --total=<num>   The maximum total score attainable
"""

const PROMPTS = [
    "They're equally good"
    "Alternative 1 is better"
    "Alternative 2 is better"
]

const MENU = RadioMenu(PROMPTS)

clearscr() = print("\x1B[2J\x1B[0f")

print_alternatives(criteria, levels, base, lhs, rhs; indent="") =
    print_alternatives(stdout, criteria, levels, base, lhs, rhs, indent=indent)

function print_alternatives(io::IO, criteria, levels, base, lhs, rhs; indent="")

    for (i, c) in enumerate([lhs, rhs])
        println(io, indent, "Alternative ", i, ":\n")
        for (criterion, level) in zip(base, c)
            println(io, indent, " "^3, criteria[criterion], ": ",
                    levels[criterion][level])
        end
        println(io)
    end

end

function ask_user(s, base, lhs, rhs)

    clearscr()

    print_alternatives(Pepper.criteria(s), Pepper.levels(s),
                       base, lhs, rhs)

    choice = request("Which is better?\n", MENU)
    if choice ∉ 1:3
        println()
        exit()
    end

    return choice

end

function parse(lines::Vector, delegate)
    criterion = nothing
    for line in lines
        line = strip(line)
        err() = error("malformed line: $line")
        if endswith(line, ":")
            criterion = rstrip(chop(line))
            Pepper.addcriterion(delegate, criterion)
        elseif startswith(line, "-")
            level = lstrip(chop(line, head=1, tail=0))
            pts = nothing
            parts = split(level, ":")
            1 ≤ length(parts) ≤ 2 || err()
            if length(parts) > 1
                level = strip(parts[1])
                pts = tryparse(Int, parts[2])
                pts ≡ nothing && err()
            end
            Pepper.addlevel(delegate, level)
            if pts ≢ nothing
                Pepper.setpts(delegate, criterion => level, pts)
            end
        elseif !isempty(line)
            err()
        end
    end
end

function show(io::IO, s::Pepper.System)
    first = true
    for (criterion, levels) in zip(Pepper.criteria(s), Pepper.levels(s))
        if first
            first = false
        else
            println()
        end
        print(io, criterion, ":")
        for level in levels
            println()
            print(io, " "^4, "- ", level, ": ",
                  something(Pepper.getpts(s, criterion=>level), "~"))
        end
    end
end

function cli()

    args = docopt(doc)

    s = Pepper.System()

    parse(readlines(args["<criteria>"]), s)

    if args["--total"] ≡ nothing
        total = nothing
    else
        total = Base.parse(Int, args["--total"])
    end

    Pepper.paprika(ask_user, s,
        maxdegree = Base.parse(Int, args["--degree"]),
        total = total)

    clearscr()

    println(s)

    println()

end

__init__() = TerminalMenus.config(ctrl_c_interrupt=false)

end
