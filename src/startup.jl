"""
This file initializes the IscaTools module by defining the directories relevant to the particular Isca experiment being resorted and analysed by IscaTools.
"""

function irootdict()

    idict = Dict{AbstractString,AbstractString}()
    idict["root"] = ""; idict["raw"] = ""; idict["ana"] = "";
    idict["experiment"] = ""; idict["configuration"] = "";
    idict["spinup"] = ""; idict["control"] = "";
    idict["fname"] = "";

    return idict

end

function iscaspin(iroot::AbstractDict)

    efol = joinpath(iroot["root"],iroot["experiment"]);
    sfol = joinpath(iroot["root"],iroot["experiment"],"spinup");
    if isdir(sfol)
        @info "$(Dates.now()) - A spinup configuration folder has been identified in $(efol)."
        return true;
    else
        @info "$(Dates.now()) - No spinup configuration folder was identified in $(efol)."
        return false;
    end

end

function iscawelcome()

    ftext = joinpath(@__DIR__,"../extra/welcome.txt");
    lines = readlines(ftext); count = 0; nl = length(lines);
    for l in lines; count += 1;
       if any(count .== [1,2]); print(Crayon(bold=true),"$l\n");
       elseif count == nl;      print(Crayon(bold=false),"$l\n\n");
       else;                    print(Crayon(bold=false),"$l\n");
       end
    end

end

function iscaroot(
    experiment::AbstractString,
    config::AbstractString,
    prjpath::AbstractString
)

    iroot = irootdict(); iroot["root"] = prjpath;
    iroot["raw"] = joinpath(prjpath,experiment,config)

    if !isdir(iroot["raw"])
        error("$(Dates.now()) - The folder $(iroot["raw"]) does not exist.  Please ensure that you have entered the correct project PATH, EXPERIMENT (if applicable), and CONFIGURATION details.")
    end

    iroot["ana"] = joinpath(prjpath,experiment,config,"analysis")
    iroot["experiment"] = experiment; iroot["configuration"] = config;

    @info """$(Dates.now()) - $(BOLD("PROJECT DETAILS:"))
      $(BOLD("Project Directory:")) $prjpath
      $(BOLD("Raw Data Directory:")) $(iroot["raw"])
      $(BOLD("Analysis Directory:")) $(iroot["ana"])
      $(BOLD("Experiment | Configuration:")) $experiment | $config
    """

    if iscaspin(iroot)
        iroot["spinup"]  = replace(iroot["raw"],config=>"spinup")
        iroot["control"] = replace(iroot["raw"],config=>"control")
        @info """$(Dates.now()) - $(BOLD("SPINUP DIRECTORIES:"))
          $(BOLD("Spinup Directory:"))  $(iroot["spinup"])
          $(BOLD("Control Directory:")) $(iroot["control"])
        """
    end

    return iroot

end

function iscaroot(
    experiment::AbstractString,
    config::AbstractString,
    rawpath::AbstractString,
    anapath::AbstractString
)

    iroot = irootdict();
    iroot["raw"] = joinpath(rawpath,experiment,config)

    if !isdir(iroot["raw"])
        error("$(Dates.now()) - The folder $(iroot["raw"]) does not exist.  Please ensure that you have entered the correct project PATH, EXPERIMENT (if applicable), and CONFIGURATION details.")
    end

    iroot["ana"] = joinpath(anapath,experiment,config)
    if !isdir(iroot["ana"])
        @info "$(Dates.now()) - The folder $(iroot["ana"]) does not exist.  Creating now ..."
    end

    iroot["experiment"] = experiment; iroot["configuration"] = config;

    @info """$(Dates.now()) - $(BOLD("PROJECT DETAILS:"))
      $(BOLD("Raw Data Directory:")) $(iroot["raw"])
      $(BOLD("Analysis Directory:")) $(iroot["ana"])
      $(BOLD("Experiment | Configuration:")) $experiment | $config
    """

    if iscaspin(iroot)
        iroot["spinup"]  = replace(iroot["raw"],config=>"spinup")
        iroot["control"] = replace(iroot["raw"],config=>"control")
        @info """$(Dates.now()) - $(BOLD("SPINUP DIRECTORIES:"))
          $(BOLD("Spinup Directory:"))  $(iroot["spinup"])
          $(BOLD("Control Directory:")) $(iroot["control"])
        """
    end

    return iroot

end

function iscaroot(;
    prjpath::AbstractString="",
    rawpath::AbstractString="",
    anapath::AbstractString="",
    experiment::AbstractString="",
    config::AbstractString
)

    if prjpath == "" && !(rawpath == "" && anapath == "")
        prjpath = ENV["GFDL_DATA"];
    end

    if !(rawpath == "" && anapath == "")
          return iscaroot(experiment,config,rawpath,anapath)
    else; return iscaroot(experiment,config,prjpath)
    end

end

function iscastartup(;
    prjpath::AbstractString="",
    rawpath::AbstractString="",
    anapath::AbstractString="",
    experiment::AbstractString="",
    config::AbstractString,
    fname::AbstractString,
    welcome::Bool=true
)

    if welcome; iscawelcome() end
    iroot = iscaroot(prjpath=prjpath,rawpath=rawpath,anapath=anapath,
                     experiment=experiment,config=config)

    fnc = joinpath(iroot["raw"],"run0001","$fname.nc");
    if !isfile(fnc)
        error("$(Dates.now()) - The output file \"$fname.nc\" does not exist.  Please double-check the filename in which the Isca raw data was save into and try again.")
    else
        iroot["fname"] = "$fname.nc";
    end


    if isfile("$(iroot["raw"])/init.jld2")
        @load "$(iroot["raw"])/init.jld2" init
    else
        init = retrievetime(fnc); retrieveruns!(init,iroot)
        ds = Dataset(fnc);
        init["phalf"] = ds["phalf"][:]*100;
        init["pfull"] = ds["pfull"][:]*100;
        init["sealp"] = ds["phalf"][end]*100;;
        init["lon"]   = ds["lon"][:]*1;
        init["lat"]   = ds["lat"][:]*1;
        close(ds);
    end

    return init,iroot

end
