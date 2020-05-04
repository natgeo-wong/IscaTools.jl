# **<div align="center">IscaTools.jl</div>**

**Created By:** Nathanael Wong (nathanaelwong@fas.harvard.edu)

**Developer To-Do for v1.0:**
* [ ] Testing of `analysis` functions
* [ ] Comprehensive documentation and Jupyter notebook examples
* [ ] `iscaquery` function series development
* [ ] Calculations for the following variables:
	* [ ] Meridional Streamfunctions
	* [ ] Total Rainfall, Total Snowfall, Total Column Water
	* [ ] Eddy Kinetic Energy
	* [ ] Momentum and Heat Fluxes

## Introduction

`IscaTools.jl` is a Julia package that aims to streamline the following processes:
* Management of output from the [Isca](https://execlim.github.io/IscaWebsite/) GCM developed by the University of Exeter
* Calculation of commonly-used variables (and saving back into original NetCDF output file)
* Basic analysis of output (yearly/monthy means, etc.)

`IscaTools.jl` can be installed via
```
] add IscaTools
```

Of course, before using `IscaTools.jl`, you need to download the GCM to generate the output from:
* The Isca GCM [[GitHub](https://github.com/ExeClim/Isca)] [[Website](https://execlim.github.io/IscaWebsite/)]
