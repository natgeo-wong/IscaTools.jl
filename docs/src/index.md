# IscaTools.jl
*Tooling and Analysis for Isca GCM Output*

`IscaTools.jl` is a Julia package that:
* Management of output from the [Isca](https://execlim.github.io/IscaWebsite/) GCM developed by the University of Exeter
* Calculation of commonly-used variables (and saving back into original NetCDF output file)
* Basic analysis of output (yearly/monthy means, etc.)


## Installation
`IscaTools.jl` can be installed using Julia's built-in package manager as follows:

```
julia> ]
(@v1.4) pkg> add IscaTools
```

You can update `IscaTools.jl` to the latest version using
```
(@v1.4) pkg> update IscaTools
```

And if you want to get the latest release without waiting for me to update the Julia Registry (although this generally isn't necessary since I make a point to release patch versions as soon as I find bugs or add new working features), you may fix the version to the `master` branch of the GitHub repository:
```
(@v1.4) pkg> add IscaTools#master
```

!!! warning "NCDatasets Dependency:"
    Isca GCM Output does not necessarily follow the CF Conventions listed in `CFTime.jl`, and therefore this causes problems with the stable release of `NCDatasets.jl`.  The `master` branch of `NCDatasets.jl` resolves this problem but has not yet been released.  Please update to the `master` version of `NCDatasets.jl` by doing:
    ```
    (@v1.4) pkg> add NCDatasets#master
    ```

## Documentation

The documentation for `IscaTools.jl` is covers:
1. Tutorials - meant as an introduction to the package
2. How-to Examples - geared towards those looking for specific examples of what can be done
3. API Reference - comprehensive summary of all exported functionalities

!!! tip "A Note on the Examples:"
    All the output for the coding examples were produced using my computer with key security information (such as login info) omitted.  The examples cannot be run online because the file size requirements are too big.  Copying and pasting the code examples (with relevant directory and login information changes) should produce the same results.

## Getting help
If you are interested in using `IscaTools.jl` or are trying to figure out how to use it, please feel free to ask me questions and get in touch!  Please feel free to [open an issue](https://github.com/natgeo-wong/IscaTools.jl/issues/new) if you have any questions, comments, suggestions, etc!
