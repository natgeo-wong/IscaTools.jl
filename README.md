# **<div align="center">IscaTools.jl</div>**

<p align="center">
  <a href="https://www.repostatus.org/#active">
    <img alt="Repo Status" src="https://www.repostatus.org/badges/latest/active.svg?style=flat-square" />
  </a>
  <a href="https://travis-ci.com/github/natgeo-wong/IscaTools.jl">
    <img alt="Travis CI" src="https://travis-ci.com/natgeo-wong/IscaTools.jl.svg?branch=master&style=flat-square">
  </a>
  <a href="https://github.com/natgeo-wong/IscaTools.jl/actions?query=workflow%3ADocumentation">
    <img alt="Documentation Build" src="https://github.com/natgeo-wong/IscaTools.jl/workflows/Documentation/badge.svg">
  </a>
  <br>
  <a href="https://mit-license.org">
    <img alt="MIT License" src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square">
  </a>
  <img alt="Latest Release" src="https://img.shields.io/github/v/release/natgeo-wong/IscaTools.jl">
  <a href="https://natgeo-wong.github.io/IscaTools.jl/stable/">
    <img alt="Latest Documentation" src="https://img.shields.io/badge/docs-stable-blue.svg?style=flat-square">
  </a>
  <a href="https://natgeo-wong.github.io/IscaTools.jl/dev/">
    <img alt="Latest Documentation" src="https://img.shields.io/badge/docs-latest-blue.svg?style=flat-square">
  </a>
</p>

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
