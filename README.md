# ClimateIsca
This Julia package is geared towards the sorting and analysis of output from the Isca GCM created
by the Climate Dynamics group led by Geoffrey Vallis from the University of Exeter.  It also throws
in calculations of some of the more common atmospheric parameters such as moisture fluxes and
streamfunction calculations.

The current status of `ClimateIsca.jl` is as follows:
* Resorting of default Isca output parameters: In Development
* Analysis of variables: In Development
* Calculation of common atmospheric parameters: In Development

## Installation
`ClimateIsca.jl` is not yet a registered Julia package (ETA: January 2020).  Please clone this
package from the GitHub repository:
```
Pkg.clone("https://github.com/natgeo-wong/ClimateIsca.jl")
```

## Prerequisites:
`ClimateIsca.jl` assumes that you have set up the following environment for Isca:
```
export GFDL_DATA=(Your Isca data directory here)
```

`ClimateIsca.jl` will then create data directories at the same level as `GFDL_DATA` named
`isca_resort` and `isca_ana`, and all outputs from the `resort` and `analysis` functions will be
moved to these folders.

For example, in Odyssey/Cannon, I have my data directories set up as:
```
GFDL_DATA=/n/holylfs/LABS/kuang_lab/nwong/isca/isca_out
```

`ClimateIsca.jl` will therefore set up my resort and analysis directories as
```
/n/holylfs/LABS/kuang_lab/nwong/isca/isca_resort
/n/holylfs/LABS/kuang_lab/nwong/isca/isca_analysis
```

## Projects, Experiments and Configurations
`ClimateIsca.jl` assumes that your data output from the Isca GCM has at least two tiers:
* `Project`: Highest level, contains all your output for an entire project
* `Experiment`: Second level (optional), contains output for a group of configurations with a common setting
    - Generally meant for changes in major settings.
    - e.g. spatial resolution (T42/T85/...), radiative scheme (Grey/RRTM/...), etc.
* `Configuration`: Lowest level, contains output for a specific configuration case investigated
    - Generally meant for specific phenomenon being investigated.
    - e.g. land mask, surface heat forcing, etc.

The data results from spinups for a `Project` is assumed to be found in the `Configuration` level of the project.  If there is an `Experiment` Tier, then each `Experiment` is assumed to have a spinup.
