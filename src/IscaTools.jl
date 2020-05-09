module IscaTools

# Main file for the ClimateIsca module that resorts and conducts basic temporal analysis on the
# output for the Isca GCM created by the University of Exeter (Vallis et al. 2018)

## Modules Used
using CFTime
using Crayons, Crayons.Box
using Dates
using DelimitedFiles
using Glob
using JLD2
using NCDatasets
using Printf

## Exporting the following functions:
export
        iscaroot, iscastartup, retrievetime,
        iscainitialize, iscapre2lvl

## Including other files in the module

include("startup.jl")
include("time.jl")
include("initialize.jl")
include("frontend.jl")
#include("raw.jl")
#include("analysis.jl")
#include("calculate.jl")
#include("moisture.jl")
#include("streamfunction.jl")
#include("eddies.jl")
#include("fluxes.jl")

end # module