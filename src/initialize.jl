"""
This file initializes the Climateisca module by setting and determining the
ECMWF reanalysis parameters to be analyzed and the regions upon which the data
are to be extracted from.  Functionalities include:
    - Setting up of reanalysis module type
    - Setting up of reanalysis parameters to be analyzed
    - Setting up of time steps upon which data are to be downloaded
    - Setting up of region of analysis based on ClimateEasy

"""

# Climateisca Parameter Setup

function iscaparameterscopy(;overwrite::Bool=false)

    jfol = joinpath(DEPOT_PATH[1],"files/ClimateIsca/"); mkpath(jfol);
    ftem = joinpath(@__DIR__,"../extra/partemplate.txt")
    fpar = joinpath(jfol,"iscaparameters.txt")

    if !overwrite
        if !isfile(fpar)
            @debug "$(Dates.now()) - Unable to find iscaparameters.txt, copying data from partemplate.txt ..."
            cp(ftem,fpar,force=true);
        end
    else
        @warn "$(Dates.now()) - Overwriting iscaparameters.txt in $jfol ..."
        cp(ftem,fpar,force=true);
    end

    return fpar

end

function iscaparametersload()

    @debug "$(Dates.now()) - Loading information on the output parameters from the Isca GCM."
    return readdlm(iscaparameterscopy(),',',comments=true);

end

function iscaparametersload(init::AbstractDict)

    @debug "$(Dates.now()) - Loading information on the output parameters from the Isca GCM."
    allparams = readdlm(iscaparameterscopy(),',',comments=true);

    @debug "$(Dates.now()) - Filtering out for parameters in the $(init["modulename"]) module."
    parmods = allparams[:,1]; return allparams[(parmods.==init["moduletype"]),:];

end

function iscaparametersdisp(parlist::AbstractArray,init::AbstractDict)
    @info "$(Dates.now()) - The following variables are offered in the $(init["modulename"]) module:"
    for ii = 1 : size(parlist,1); @info "$(Dates.now()) - $(ii)) $(parlist[ii,6])" end
end

function iscaparametersadd(fadd::AbstractString)

    if !isfile(fadd); error("$(Dates.now()) - The file $(fadd) does not exist."); end
    ainfo = readdlm(fadd,',',comments=true); aparID = ainfo[:,2]; nadd = length(aparID);

    for iadd = 1 : nadd
        iscaparametiscadd(modID=ainfo[iadd,1],parID=ainfo[iadd,2],ncID=ainfo[iadd,3],
                        isca5=ainfo[iadd,4],iscai=ainfo[iadd,5],
                        full=ainfo[iadd,6],unit=ainfo[iadd,7],throw=false);
    end

end

function iscaparametiscadd(;
    modID::AbstractString, parID::AbstractString, ncID::AbstractString,
    full::AbstractString, unit::AbstractString,
    throw::Bool=true
)

    fpar = iscaparameterscopy(); pinfo = iscaparametersload(); eparID = pinfo[:,2];

    if sum(eparID.==parID) > 0

        if throw
            error("$(Dates.now()) - Parameter ID already exists.  Please choose a new parID.")
        else
            @info "$(Dates.now()) - $(parID) has already been added to iscaparameters.txt"
        end

    else

        open(fpar,"a") do io
            writedlm(io,[modID parID ncID full unit],',')
        end

    end

end

# Initialization

function iscamodule(moduleID::AbstractString,init::AbstractDict)

    imod = Dict{AbstractString,Any}()
    imod["moduletype"] = moduleID;

    if     moduleID == "dsfc"; imod["modulename"] = "dry surface";
    elseif moduleID == "dpre"; imod["modulename"] = "dry pressure";
    elseif moduleID == "msfc"; imod["modulename"] = "moist surface";
    elseif moduleID == "mpre"; imod["modulename"] = "moist pressure";
    elseif moduleID == "imul"; imod["modulename"] = "isca multiplied";
    elseif moduleID == "half"; imod["modulename"] = "half-pressure";
    elseif moduleID == "held"; imod["modulename"] = "held-suarez";
    elseif moduleID == "csfc"; imod["modulename"] = "calc surface";
    elseif moduleID == "cpre"; imod["modulename"] = "calc pressure";
    end

    if occursin("sfc",moduleID)
        @debug "$(Dates.now()) - A surface module was selected, and therefore we will save 'sfc' into the parameter level Dictionary."
        imod["levels"] = ["sfc"];
    elseif moduleID == "half"
        @debug "$(Dates.now()) - A half-pressure module was selected, and therefore all available pressure levels will be saved into the parameter Dictionary."
        imod["levels"] = init["halfs"]
    else
        @debug "$(Dates.now()) - A full-pressure module was selected, and therefore all available pressure levels will be saved into the parameter Dictionary."
        imod["levels"] = init["fulls"]
    end

    imod["halfs"] = init["halfs"];
    imod["fulls"] = init["fulls"];
    imod["sealp"] = init["sealp"];

    return imod

end

function iscaparameters(parameterID::AbstractString,pressure::Real,imod::AbstractDict)

    parlist = iscaparametersload(imod); mtype = imod["moduletype"];

    if sum(parlist[:,2] .== parameterID) == 0
        error("$(Dates.now()) - Invalid parameter choice for \"$(uppercase(mtype))\".  Call queryipar(modID=$(mtype),parID=$(parameterID)) for more information.")
    else
        ID = (parlist[:,2] .== parameterID);
    end

    parinfo = parlist[ID,:];
    @info "$(Dates.now()) - Climateisca will analyze $(parinfo[3]) data."

    if occursin("sfc",mtype)
        return Dict("ID"=>parinfo[2],"name"=>parinfo[3],"unit"=>parinfo[4],"level"=>"sfc");
    else

        if pressure == 0
            error("$(Dates.now()) - You defined a pressure module \"$(uppercase(mtype))\" but you did not specify a pressure.")
        end

        lvl = iscapre2lvl(pressure,imod)
        return Dict("ID"=>parinfo[2],"name"=>parinfo[3],"unit"=>parinfo[4],"level"=>undef);

    end

end

function iscainitialize(
    init::AbstractDict;
    modID::AbstractString, parID::AbstractString,
    prehPa::Real=0
)

    imod = iscamodule(modID,init); ipar = iscaparameters(parID,prehPa,imod);
    itime = deepcopy(init);
    delete!(itime,"halfs"); delete!(itime,"fulls"); delete!(itime,"sealp");

    return imod,ipar,itime

end
