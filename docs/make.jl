using Documenter
using IscaTools

makedocs(
    modules  = [IscaTools],
    doctest  = false,
    format   = Documenter.HTML(
        collapselevel = 1,
        prettyurls    = false
    ),
    authors  = "Nathanael Wong",
    sitename = "IscaTools.jl",
    pages    = [
        "Home"     => "index.md",
        # "Tutorials" => [
        #     "Initilization"        => "tutorials/initialize.md",
        #     "Preliminary Analysis" => "tutorials/analysis.md"
        # ]
    ]
)

deploydocs(
    repo = "github.com/natgeo-wong/IscaTools.jl.git",
)
