using HiddenFiles, Documenter

Documenter.makedocs(
    clean = true,
    doctest = true,
    modules = Module[HiddenFiles],
    repo = "",
    highlightsig = true,
    sitename = "HiddenFiles Documentation",
    expandfirst = [],
    pages = [
        "Index" => "index.md",
    ]
)

deploydocs(;
    repo  =  "github.com/jakewilliami/HiddenFiles.jl.git",
)
