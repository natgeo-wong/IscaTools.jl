"""
This file contains all the functions in ClimateIsca.jl that deal with handling of Isca GCM
parameters, such as:
    - Loading of parameter information
    - Checking if parameter is a surface variable
    - Saving parameter data into NetCDF files
    - Reading parameter data from NetCDF files

"""

function iscaparis(pinfo::Dict,inquiry::AbstractString)

    tf = sum(inquiry==split(pinfo["name"],"_"))
    if !(tf==0); return true; else; return false; end

end

function iscaparfolder(path::AbstractString,parname::AbstractString)
    pfol = joinpath(path,parname)
end

function iscaparfolder(path::AbstractString,parname::AbstractString,level::Integer)
    pfol = joinpath(path,parname,"$(parname)-sig$(sprintf1("%02d",level))")
end

function iscaparload(parameterID::Integer)

    @debug "$(Dates.now()) - Loading information on parameters used in ClimateIsca.jl ..."
    params = readdlm(joinpath(@__DIR__,"parameters.txt"),',',comments=true);
    return params[params[:,1].==parameterID,2:end];

end

function iscaparload(parameterID::Array)

    @debug "$(Dates.now()) - Loading information on parameters used in ClimateIsca.jl ..."
    params = readdlm(joinpath(@__DIR__,"parameters.txt"),',',comments=true);
    cart = findall(params[:,1].==parameterID'); ind = [];
    for ii = 1 : length(cart); append!(ind,cart[ii][1]); end
    return params[ind,2:end];

end

function iscaparameter(parameterID::Integer)

    pinfo  = iscaparload(parameterID);
    return Dict("name"=>pinfo[1],"isca"=>pinfo[2],"full"=>pinfo[3],"unit"=>pinfo[4])

end

function iscapre2lvl(pinfo::Dict,allpre::Array)

    if !iscaparis(pinfo,"sfc")
        pre = [250,300,500,700,850,900]; pind = argmin(abs.(allpre.-pre'),dims=1);
        nlvl = length(bmin); level = zeros(nlvl)
        for ii = 1 : nlvl; level[ii] = pind[ii][1]; end
    else
        @info "$(Dates.now()) - Parameter chosen is a surface variable.  Setting level to 0."
        level = 0;
    end

    return level

end

## Extraction of Parameter Data

function iscaparncread(fnc::AbstractString,pinfo::Dict;timeshape=false)

    data = ncread(fnc,pinfo["isca"]); ndim = numel(size(data));

    if timeshape
        if numel(size(data)) == 4
            @debug "$(Dates.now()) - Parameter chosen has pressure levels and therefore 4 dimensions.  In order to automatically reduce dimensions after time-averaging, we shall permute the array such that the time dimension is the last dimension.";
            data = permutedims(data,[1,2,4,3]);
        end
    end

    if any(iscaparis.(pinfo,["prcp","rcnd","rcnv"])); data = data *24*60*60 end

    return data

end

function iscaparncread(fnc::AbstractString,pinfo::Dict,ncattr::Dict;timeshape=false)

    data = ncread(fnc,pinfo["isca"]); ndim = numel(size(data));

    if !iscaparis(pinfo,"sfc")
        pre = ncattr["fullpre"]; levels = iscapre2lvl(pinfo,pre); data = data[:,:,levels,:];
    end

    if timeshape
        if numel(size(data)) == 4
            @debug "$(Dates.now()) - Parameter chosen has pressure levels and therefore 4 dimensions.  In order to automatically reduce dimensions after time-averaging, we shall permute the array such that the time dimension is the last dimension.";
            data = permutedims(data,[1,2,4,3]);
        end
    end

    if any(iscaparis.(pinfo,["prcp","rcnd","rcnv"])); data = data *24*60*60 end

    return data

end

## Saving of Parameter Data

function iscaparncsave(par::AbstractArray,pinfo::Dict,yr::Integer,iroot::AbstractString,lvl="sfc");

    @load joinpath("$(iroot["data"])","isca_info.jld2") ncattr;
    lon = ncattr["longitude"]; nlon  = length(lon)
    lat = ncattr["latitude"];  nlat  = length(lat);
    pre = ncattr["fullpre"];   issfc = iscaissfc(lvl);
    dim = size(par);           nt    = dim[3];
    tspan = ncattr["timespan"]; pname = pinfo["name"];

    pdir = joinpath(root["data"],pname);

    if issfc
          pfnc = "$(pname)-$(tspan)$(sprintf1("%02d",yr)).nc"
          pdir = joinpath(root["data"],pname);
    else; pfnc = "$(pname)-lvl$(sprintf1("%02d",lvl))-$(tspan)$(sprintf1("%02d",yr)).nc"
          pdir = joinpath(root["data"],pname,"$(pname)-lvl$(sprintf1("%02d",lvl))");
    end

    if !isdir(pdir); mkpath(pdir); end
    if isfile(pfnc)
        @info "$(Dates.now()) - Unfinished netCDF file $(pfnc) detected.  Deleting."
        rm(pfnc);
    end

    var_par = pinfo["name"]; att_par = Dict("units"=>pinfo["unit"]);
    var_lon = "lon";         att_lon = Dict("units"=>"degree");
    var_lat = "lat";         att_lat = Dict("units"=>"degree");
    if issfc; var_pre = "pre"; att_lvl = Dict("units"=>"hPa"); end

    @info "$(Dates.now()) - Creating netCDF file $(pfnc) ..."
    nccreate(pfnc,var_par,"nlon",nlon,"nlat",nlat,"t",nt,atts=att_par,t=NC_FLOAT);
    nccreate(pfnc,var_lon,"nlon",nlon,atts=att_lon,t=NC_FLOAT);
    nccreate(pfnc,var_lat,"nlat",nlat,atts=att_lat,t=NC_FLOAT);
    if issfc; nccreate(pfnc,var_pre,"npre",1,atts=att_lvl,t=NC_FLOAT); end

    @info "$(Dates.now()) - Saving resorted Isca data to netCDF file $(pfnc) ..."
    ncwrite(par,pfnc,var_par);
    ncwrite(lon,pfnc,var_lon);
    ncwrite(lat,pfnc,var_lat);
    if issfc; ncwrite([pre[lvl]],pfnc,var_pre); end

    @debug "$(Dates.now()) - NetCDF.jl's ncread causes memory leakage.  Using ncclose() as a workaround."
    ncclose()

    @info "$(Dates.now()) - Moving $(pfnc) to data directory $(pdir)"
    if isfile(joinpath(pdir,pfnc));
        @info "$(Dates.now()) - An older version of $(pfnc) exists in the $(pdir) directory.  Overwriting."
    end
    mv(pfnc,joinpath(pdir,pfnc),force=true);

end

function iscaparncsave(par::AbstractArray,pinfo::Dict,ncattr::Dict,
                       yr::Integer,iroot::AbstractString,lvl="sfc");

    lon = ncattr["longitude"]; nlon  = length(lon)
    lat = ncattr["latitude"];  nlat  = length(lat);
    pre = ncattr["fullpre"];   issfc = iscaissfc(lvl);
    dim = size(par);           nt    = dim[3];
    tspan = ncattr["timespan"]; pname = pinfo["name"];

    pdir = joinpath(root["data"],pname);

    if issfc
         pfnc = "$(pname)-$(tspan)$(sprintf1("%02d",yr)).nc"
         pdir = joinpath(root["data"],pname);
    else; pfnc = "$(pname)-lvl$(sprintf1("%02d",lvl))-$(tspan)$(sprintf1("%02d",yr)).nc"
         pdir = joinpath(root["data"],pname,"$(pname)-lvl$(sprintf1("%02d",lvl))");
    end

    if !isdir(pdir); mkpath(pdir); end
    if isfile(pfnc)
       @info "$(Dates.now()) - Unfinished netCDF file $(pfnc) detected.  Deleting."
       rm(pfnc);
    end

    var_par = pinfo["name"]; att_par = Dict("units"=>pinfo["unit"]);
    var_lon = "lon";         att_lon = Dict("units"=>"degree");
    var_lat = "lat";         att_lat = Dict("units"=>"degree");
    if issfc; var_pre = "pre"; att_lvl = Dict("units"=>"hPa"); end

    @info "$(Dates.now()) - Creating netCDF file $(pfnc) ..."
    nccreate(pfnc,var_par,"nlon",nlon,"nlat",nlat,"t",nt,atts=att_par,t=NC_FLOAT);
    nccreate(pfnc,var_lon,"nlon",nlon,atts=att_lon,t=NC_FLOAT);
    nccreate(pfnc,var_lat,"nlat",nlat,atts=att_lat,t=NC_FLOAT);
    if issfc; nccreate(pfnc,var_pre,"npre",1,atts=att_lvl,t=NC_FLOAT); end

    @info "$(Dates.now()) - Saving resorted Isca data to netCDF file $(pfnc) ..."
    ncwrite(par,pfnc,var_par);
    ncwrite(lon,pfnc,var_lon);
    ncwrite(lat,pfnc,var_lat);
    if issfc; ncwrite(pre[lvl],pfnc,var_pre); end

    @debug "$(Dates.now()) - NetCDF.jl's ncread causes memory leakage.  Using ncclose() as a workaround."
    ncclose()

    @info "$(Dates.now()) - Moving $(pfnc) to data directory $(pdir)"
    if isfile(joinpath(pdir,pfnc));
       @info "$(Dates.now()) - An older version of $(pfnc) exists in the $(pdir) directory.  Overwriting."
    end
    mv(pfnc,joinpath(pdir,pfnc),force=true);

end
