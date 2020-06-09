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

    efol = joinpath(iroot["root"],"raw",iroot["experiment"]);
    sfol = joinpath(iroot["root"],"raw",iroot["experiment"],"spinup");
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
    iroot["raw"] = joinpath(prjpath,"raw",experiment,config)

    if !isdir(iroot["raw"])
        error("$(Dates.now()) - The folder $(iroot["raw"]) does not exist.  Please ensure that you have entered the correct project PATH, EXPERIMENT (if applicable), and CONFIGURATION details.")
    end

    iroot["ana"] = joinpath(prjpath,"ana",experiment,config)
    iroot["experiment"] = experiment; iroot["configuration"] = config;

    @info "$(Dates.now()) - $(BOLD("PROJECT DETAILS:"))\n  $(BOLD("Root Directory:")) $prjpath\n  $(BOLD("Experiment:")) $experiment\n  $(BOLD("Configuration:")) $config"
    @info "$(Dates.now()) - Isca GCM data RAW DATA directory: $(iroot["raw"])."
    @info "$(Dates.now()) - Isca GCM data ANALYSIS directory: $(iroot["ana"])."

    if iscaspin(iroot)
        iroot["spinup"]  = replace(iroot["raw"],config=>"spinup")
        iroot["control"] = replace(iroot["raw"],config=>"control")
        @info "$(Dates.now()) - Isca GCM data SPINUP directory: $(iroot["spinup"])."
        @info "$(Dates.now()) - Isca GCM data CONTROL directory: $(iroot["control"])."
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
    iroot["experiment"] = experiment; iroot["configuration"] = config;

    @info "$(Dates.now()) - $(BOLD("PROJECT DETAILS:"))\n  $(BOLD("Raw Directory:")) $rawpath\n  $(BOLD("Experiment:")) $experiment\n  $(BOLD("Configuration:")) $config"
    @info "$(Dates.now()) - Isca GCM data RAW DATA directory: $(iroot["raw"])."
    @info "$(Dates.now()) - Isca GCM data ANALYSIS directory: $(iroot["ana"])."

    if iscaspin(iroot)
        iroot["spinup"]  = replace(iroot["raw"],config=>"spinup")
        iroot["control"] = replace(iroot["raw"],config=>"control")
        @info "$(Dates.now()) - Isca GCM data SPINUP directory: $(iroot["spinup"])."
        @info "$(Dates.now()) - Isca GCM data CONTROL directory: $(iroot["control"])."
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


    init = retrievetime(fnc); retrieveruns!(init,iroot)

    ds = Dataset(fnc);
    init["phalf"] = ds["phalf"][:]*100;
    init["pfull"] = ds["pfull"][:]*100;
    init["sealp"] = ds["phalf"][end]*100;;
    init["lon"]   = ds["lon"][:]*1;
    init["lat"]   = ds["lat"][:]*1;
    close(ds);

    return init,iroot

end
