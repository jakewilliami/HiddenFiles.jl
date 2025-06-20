using HiddenFiles, Documenter

Documenter.makedocs(
    clean = true,
    doctest = true,
    checkdocs = :exports,  # discourse.julialang.org/t/70299/2
    modules = Module[HiddenFiles],
    repo = "",
    highlightsig = true,
    sitename = "HiddenFiles Documentation",
    expandfirst = [],
    pages = ["Index" => "index.md"],
)

deploydocs(; repo = "github.com/jakewilliami/HiddenFiles.jl.git",)
