# Pepper.jl

The `Pepper` module implements the [PAPRIKA algorithm][1] of Hansen and
Ombler.

**Note:** Because of the current compilation latency in Julia (despite any
precompilation), Pepper may take quite a while to start (it uses [JuMP][2]
internally, for example). If you're going to run it repeatedly from the
command line, you may want to check out [PackageCompiler][3].

To install Pepper, simply start up Julia and press `]` at the prompt, to get
the package manager—and then add Pepper via the repository URL:
```
pkg> add https://github.com/mlhetland/Pepper.jl
```

You can now run the Pepper command-line interface using the following shell
command:
```
julia -e 'using Pepper.CLI; CLI.cli()' -- [options] ‹input›
```
You may want to create an alias for this, of course, e.g. (in [fish][4]):
```
alias pepper="julia -e 'using Pepper.CLI; CLI.cli()' --"
```
Then you can get an overview over available options in the current version by
running:
```
$ pepper -h
```
This will only work if you're still in this directory, though; in order to be
able to import the `Pepper` module in general, you must add the `src`
directory to your [`JULIA_LOAD_PATH`][5]. For example, if you've got the
`Pepper.jl` in your home directory, you can do that as following (again in
[fish][4]):
```
set -x JULIA_LOAD_PATH "$JULIA_LOAD_PATH:$HOME/Pepper.jl/src"
```
To actually run the program, you'll need an input file specifying a set of
criteria, each with several levels, or categories. You specify this using a
[YAML][6]-  or [TaskPaper][7]-like syntax, where criteria end with colons and
categories start with a dash. For example, the example from the [Wikipedia
article][1] becomes:

```yaml
Education:
    - poor
    - good
    - very good
    - excellent
Experience:
    - less than 2 years
    - 2–5 years
    - more than 5 years
References:
    - poor
    - good
Social skills:
    - poor
    - good
Enthusiasm:
    - poor
    - good
```

Make sure the categories are listed from worst to best for each criterion.

Run your `pepper` alias with this file as its argument, and you'll be asked to
rank various combinations. Once you're done, the program prints out a point
system with a score for each category.

You can also specify some of the scores ahead of time, as in the following:

```yaml
References:
    - poor
    - good
Social skills:
    - poor
    - good
Enthusiasm:
    - poor
    - good: 5
```

You can also specify the maximum point total with the `--total` (or `-t`)
argument. So for example, with the previous file in `test.yaml`, you could
run:

```
$ pepper -t 10 test.yaml
```

You might then (after answering a series of questions) end up with output
like:

```
References:
    - poor: 0
    - good: 2
Social skills:
    - poor: 0
    - good: 3
Enthusiasm:
    - poor: 0
    - good: 5
```

[1]: http://en.wikipedia.org/wiki/Potentially_all_pairwise_rankings_of_all_possible_alternatives
[2]: https://github.com/JuliaOpt/JuMP.jl
[3]: https://github.com/JuliaLang/PackageCompiler.jl
[4]: https://fishshell.com
[5]: https://docs.julialang.org/en/v1/manual/environment-variables/index.html
[6]: https://yaml.org
[7]: https://www.taskpaper.com
