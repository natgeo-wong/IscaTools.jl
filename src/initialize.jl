"""
This file initializes the IscaTools module by setting and determining the
ECMWF reanalysis parameters to be analyzed and the regions upon which the data
are to be extracted from.  Functionalities include:
    - Setting up of reanalysis module type
    - Setting up of reanalysis parameters to be analyzed
    - Setting up of time steps upon which data are to be downloaded
    - Setting up of region of analysis based on ClimateEasy

"""

# IscaTools Parameter Setup

function iscaparametercopy(;overwrite::Bool=false)

    jfol = joinpath(DEPOT_PATH[1],"files/IscaTools/"); mkpath(jfol);
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

function iscaparameterload()

    @debug "$(Dates.now()) - Loading information on the output parameters from the Isca GCM."
    return readdlm(iscaparametercopy(),',',comments=true);

end

function iscaparameterload(init::AbstractDict)

    @debug "$(Dates.now()) - Loading information on the output parameters from the Isca GCM."
    allparams = readdlm(iscaparametercopy(),',',comments=true);

    @debug "$(Dates.now()) - Filtering out for parameters in the $(init["modulename"]) module."
    parmods = allparams[:,1]; return allparams[(parmods.==init["moduletype"]),:];

end

function iscaparameterdisp(parlist::AbstractArray,init::AbstractDict)
    @info "$(Dates.now()) - The following variables are offered in the $(init["modulename"]) module:"
    for ii = 1 : size(parlist,1); @info "$(Dates.now()) - $(ii)) $(parlist[ii,6])" end
end

function iscaparameteradd(fadd::AbstractString)

    if !isfile(fadd); error("$(Dates.now()) - The file $(fadd) does not exist."); end
    ainfo = readdlm(fadd,',',comments=true); aparID = ainfo[:,2]; nadd = length(aparID);

    for iadd = 1 : nadd
        iscaparametiscadd(modID=ainfo[iadd,1],parID=ainfo[iadd,2],ncID=ainfo[iadd,3],
                        isca5=ainfo[iadd,4],iscai=ainfo[iadd,5],
                        full=ainfo[iadd,6],unit=ainfo[iadd,7],throw=false);
    end

end

function iscaparameteradd(;
    modID::AbstractString, parID::AbstractString, ncID::AbstractString,
    full::AbstractString, unit::AbstractString,
    throw::Bool=true
)

    fpar = iscaparametercopy(); pinfo = iscaparameterload(); eparID = pinfo[:,2];

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
        imod["levels"] = init["phalf"]
    else
        @debug "$(Dates.now()) - A full-pressure module was selected, and therefore all available pressure levels will be saved into the parameter Dictionary."
        imod["levels"] = init["pfull"]
    end

    imod["phalf"] = init["phalf"];
    imod["pfull"] = init["pfull"];
    imod["sealp"] = init["sealp"];
    imod["lon"]   = init["lon"];
    imod["lat"]   = init["lat"];

    return imod

end

function iscaparameter(parameterID::AbstractString,pressure::Real,imod::AbstractDict)

    parlist = iscaparameterload(imod); mtype = imod["moduletype"];

    if sum(parlist[:,2] .== parameterID) == 0
        error("$(Dates.now()) - Invalid parameter choice for \"$(uppercase(mtype))\".  Call queryipar(modID=$(mtype),parID=$(parameterID)) for more information.")
    else
        ID = (parlist[:,2] .== parameterID);
    end

    parinfo = parlist[ID,:];
    @info "$(Dates.now()) - IscaTools will analyze $(parinfo[3]) data."

    if occursin("sfc",mtype)

        if pressure != 0
            @warn "$(Dates.now()) - You asked to analyze data at pressure $(pressure) Pa but have chosen a surface module variable.  Setting pressure level to \"SFC\" by default"
        end
        return Dict("ID"=>parinfo[2],"name"=>parinfo[3],"unit"=>parinfo[4],"level"=>"sfc");

    else

        if pressure == 0

            @warn "$(Dates.now()) - You defined a pressure module \"$(uppercase(mtype))\" but you did not specify a pressure.  Setting pressure level to \"ALL\" - this may prevent usage of some IscaTool functionalities."
            return Dict(
                "ID"=>parinfo[2],"name"=>parinfo[3],
                "unit"=>parinfo[4],"level"=>"all"
            );

        else

            lvl = iscapre2lvl(pressure,imod)
            @info "$(Dates.now()) - You have requested $(uppercase(parinfo[3])) data at pressure $(pressure) Pa.  Based on a reference pressure of $(imod["sealp"]) Pa, this corresponds to σ-level $lvl out of $(length(imod["levels"]))."

            return Dict(
                "ID"=>parinfo[2],"name"=>parinfo[3],
                "unit"=>parinfo[4],"level"=>lvl
            );

        end

    end

end

function iscatime(init)

    itime = deepcopy(init);
    delete!(itime,"halfs"); delete!(itime,"fulls"); delete!(itime,"sealp");
    delete!(itime,"lon"); delete!(itime,"lat");

    return itime

end

function iscainitialize(
    init::AbstractDict;
    modID::AbstractString, parID::AbstractString,
    pressure::Real=0
)

    imod  = iscamodule(modID,init);
    ipar  = iscaparameter(parID,pressure,imod);
    itime = iscatime(init);

    return imod,ipar,itime

end
