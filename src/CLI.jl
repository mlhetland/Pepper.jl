# Command-line interface for Pepper.jl

module CLI

using DocOpt, REPL.TerminalMenus
using Pepper

const doc = """
Usage:
    pepper [options] <criteria>

Options:
    -h, --help          Show this screen
    -d, --degree=<num>  Maximum number of criteria per question [default: 2]
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
    for line in lines
        line = strip(line)
        if endswith(line, ":")
            Pepper.addcriterion(delegate, rstrip(chop(line)))
        elseif startswith(line, "-")
            Pepper.addlevel(delegate, lstrip(chop(line, head=1, tail=0)))
        elseif !isempty(line)
            error("malformed line: $line")
        end
    end
end

function cli()

    args = docopt(doc)

    s = Pepper.System()

    parse(readlines(args["<criteria>"]), s)

    Pepper.paprika(ask_user, s, maxdegree=Base.parse(Int, args["--degree"]))

    clearscr()

    for (criterion, levels) in zip(Pepper.criteria(s), Pepper.levels(s))
        println(criterion, ":")
        for level in levels
            println(" "^4, level, ": ",
                    Pepper.getpts(s, criterion=>level))
        end
    end

    println()

end

__init__() = TerminalMenus.config(ctrl_c_interrupt=false)

end
