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
using NumericalIntegration
using Printf
using Statistics

## Exporting the following functions:
export
        iscawelcome, iscaroot, iscastartup, iscainitialize, iscancread, iscaanalysis,
        iscarawfolder, iscarawname, iscarawread,
        iscaanafolder, iscaananame, iscaanaread,
        iscaparameterload, iscaparametercopy, iscaparameteradd,
        iscastreamfunction,
        retrievetime, iscapre2lvl

## Including other files in the module

include("startup.jl")
include("time.jl")
include("initialize.jl")
include("analysis.jl")
include("frontend.jl")
#include("raw.jl")
#include("calculate.jl")
#include("moisture.jl")
include("streamfunction.jl")
#include("eddies.jl")
#include("fluxes.jl")

end # module
