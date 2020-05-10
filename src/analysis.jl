"""
This file initializes the IscaTools module by setting and determining the
ECMWF reanalysis parameters to be analyzed and the regions upon which the data
are to be extracted from.  Functionalities include:
    - Setting up of reanalysis module type
    - Setting up of reanalysis parameters to be analyzed
    - Setting up of time steps upon which data are to be downloaded
    - Setting up of region of analysis based on ClimateEasy

"""

function iscananmean(data)
    dataii = @view data[data .!= NaN32]
    if dataii != []; return mean(dataii); else; return NaN32; end
end

function iscaanalysis(
    init::AbstractDict, iroot::AbstractDict;
    modID::AbstractString, parID::AbstractString,
    plvls::Union{AbstractString,Integer,Vector{<:Real}}
)

    if typeof(plvls) <: Array
        for p in plvls
            imod,ipar,itime = iscainitialize(init;modID=modID,parID=parID,pressure=p);
            iscaanalysis(imod,ipar,itime,iroot)
        end
    else
        if plvls == "sfc"
              imod,ipar,itime = iscainitialize(init;modID=modID,parID=parID)
        else; imod,ipar,itime = iscainitialize(init;modID=modID,parID=parID,pressure=plvls);
        end
        iscaanalysis(imod,ipar,itime,iroot)
    end

end

function iscaanalysis(
    imod::AbstractDict, ipar::AbstractDict, itime::AbstractDict, iroot::AbstractDict
)

    if itime["nhr"] > 1;

        if any(uppercase(itime["calendar"]) .== ["NOLEAP","GREGORIAN"])
            for irun = 1 : itime["nruns"]
                iscaanalysis365diurnal(imod,ipar,itime,iroot,irun);
            end
        elseif itime["ndy"] == 360
            for irun = 1 : itime["nruns"];
                iscaanalysis360diurnal(imod,ipar,itime,iroot,irun);
            end
        elseif itime["ndy"] == 30 && mod(12,itime["nruns"]) == 0
            nruns = round(Int,itime["nruns"]/12)
            for irun = 1 : nruns;
                iscaanalysis30diurnal(imod,ipar,itime,iroot,irun);
            end
        else
            for irun = 1 : itime["nruns"];
                iscaanalysisgendiurnal(imod,ipar,itime,iroot,irun);
            end
        end

    else

        if any(uppercase(itime["calendar"]) .== ["NOLEAP","GREGORIAN"])
            for irun = 1 : itime["nruns"]
                iscaanalysis365daily(imod,ipar,itime,iroot,irun);
            end
        elseif itime["ndy"] == 360
            for irun = 1 : itime["nruns"];
                iscaanalysis360daily(imod,ipar,itime,iroot,irun);
            end
        elseif itime["ndy"] == 30 && mod(12,itime["nruns"]) == 0
            nruns = round(Int,itime["nruns"]/12)
            for irun = 1 : nruns;
                iscaanalysis30daily(imod,ipar,itime,iroot,irun);
            end
        else
            for irun = 1 : itime["nruns"];
                iscaanalysisgendaily(imod,ipar,itime,iroot,irun);
            end
        end

    end

end


function iscaanalysis360daily(
    imod::AbstractDict, ipar::AbstractDict, itime::AbstractDict, iroot::AbstractDict,
    irun::Integer
)

    rds,rvar = iscarawread(ipar,iroot,irun=irun);
    attr = Dict{AbstractString,Any}();
    lon = rds["lon"][:]*1; nlon = length(lon)
    lat = rds["lat"][:]*1; nlat = length(lat)
    lvl = ipar["level"];

    if lvl != "sfc"; raw = rvar[:,:,lvl,:]*1; else; raw = rvar[:]*1; end; close(rds);
    raw = reshape(raw,nlon,nlat,:,12)

    davg = zeros(Float32,nlon,nlat,13); dstd = zeros(Float32,nlon,nlat,13);
    dmax = zeros(Float32,nlon,nlat,13); dmin = zeros(Float32,nlon,nlat,13);

    zavg = zeros(Float32,nlat,13); zstd = zeros(Float32,nlat,13);
    zmax = zeros(Float32,nlat,13); zmin = zeros(Float32,nlat,13);

    mavg = zeros(Float32,nlon,13); mstd = zeros(Float32,nlon,13);
    mmax = zeros(Float32,nlon,13); mmin = zeros(Float32,nlon,13);

    for mo = 1 : 12

        @info "$(Dates.now()) - Analyzing $(uppercase(ipar["name"])) data for MONTH $mo of RUN $irun ..."
        rawii = @view raw[:,:,:,mo]

        @debug "$(Dates.now()) - Extracting information on monthly climatology ..."
        davg[:,:,mo] = mean(rawii,dims=3);
        dstd[:,:,mo] = std(rawii,dims=3);
        dmax[:,:,mo] = maximum(rawii,dims=3);
        dmin[:,:,mo] = minimum(rawii,dims=3);

    end

    @info "$(Dates.now()) - Calculating yearly climatology for $(uppercase(ipar["name"])) for RUN $irun ..."
    davg[:,:,end] = mean(davg[:,:,1:12],dims=3);
    dstd[:,:,end] = mean(dstd[:,:,1:12],dims=3);
    dmax[:,:,end] = maximum(dmax[:,:,1:12],dims=3);
    dmin[:,:,end] = minimum(dmin[:,:,1:12],dims=3);

    @info "$(Dates.now()) - Calculating zonal-averaged climatology for $(uppercase(ipar["name"])) for RUN $irun ..."
    for imo = 1 : 12, ilat = 1 : nlat
        zavg[ilat,imo] = iscananmean(@view davg[:,ilat,imo]);
        zstd[ilat,imo] = iscananmean(@view dstd[:,ilat,imo]);
        zmax[ilat,imo] = iscananmean(@view dmax[:,ilat,imo]);
        zmin[ilat,imo] = iscananmean(@view dmin[:,ilat,imo]);
    end

    @info "$(Dates.now()) - Calculating meridional-averaged climatology for $(uppercase(ipar["name"])) for RUN $irun ..."
    for imo = 1 : 12, ilon = 1 : nlon
        mavg[ilon,imo] = iscananmean(@view davg[ilon,:,imo]);
        mstd[ilon,imo] = iscananmean(@view dstd[ilon,:,imo]);
        mmax[ilon,imo] = iscananmean(@view dmax[ilon,:,imo]);
        mmin[ilon,imo] = iscananmean(@view dmin[ilon,:,imo]);
    end

    iscaanasavedaily(
        [davg,dstd,dmax,dmin],
        [zavg,zstd,zmax,zmin],
        [mavg,mstd,mmax,mmin],
        imod,ipar,iroot,irun=irun
    )

end

function iscaanasavedaily(
    data::Array{Array{Float32,3},1},
    zdata::Array{Array{Float32,2},1},
    mdata::Array{Array{Float32,2},1},
    imod::AbstractDict, ipar::AbstractDict, iroot::AbstractDict;
    irun::Integer
)

    @info "$(Dates.now()) - Saving analysed $(uppercase(ipar["name"])) for RUN $irun ..."

    afol = iscaanafolder(ipar,iroot);
    fana = iscaananame(ipar,irun=irun);
    afnc = joinpath(afol,fana);

    if isfile(afnc)
        @info "$(Dates.now()) - Stale NetCDF file $(afnc) detected.  Overwriting ..."
        rm(afnc);
    end

    @debug "$(Dates.now()) - Creating NetCDF file $(afnc) for analyzed $(uppercase(ipar["name"])) for RUN $irun ..."

    ds = Dataset(afnc,"c");
    ds.dim["longitude"] = length(imod["lon"])
    ds.dim["latitude"] = length(imod["lat"])
    ds.dim["month"] = 12;

    nclon = defVar(ds,"lon", Float64, ("longitude",), attrib = Dict(
        "long_name"      => "longitude",
        "units"          => "degrees_E",
        "cartesian_axis" => "X",
        "edges"          => "lonb",
    ))

    nclat = defVar(ds,"lat", Float64, ("latitude",), attrib = Dict(
        "long_name"      => "latitude",
        "units"          => "degrees_N",
        "cartesian_axis" => "Y",
        "edges"          => "latb",
    ))

    nclon[:] = imod["lon"]
    nclat[:] = imod["lat"]

    attr_var = Dict(
        "long_name" => ipar["name"],
        "units"     => ipar["unit"],
    );

    @debug "$(Dates.now()) - Saving analyzed $(uppercase(ipar["name"])) data for RUN $irun to NetCDF file $(afnc) ..."

    v = defVar(ds,"domain_yearly_mean_climatology",Float32,
               ("longitude","latitude"),attrib=attr_var);
    v[:] = data[1][:,:,end];

    v = defVar(ds,"domain_yearly_std_climatology",Float32,
               ("longitude","latitude"),attrib=attr_var);
    v[:] = data[2][:,:,end];

    v = defVar(ds,"domain_yearly_maximum_climatology",Float32,
               ("longitude","latitude"),attrib=attr_var);
    v[:] = data[3][:,:,end];

    v = defVar(ds,"domain_yearly_minimum_climatology",Float32,
               ("longitude","latitude"),attrib=attr_var);
    v[:] = data[4][:,:,end];


    v = defVar(ds,"domain_monthly_mean_climatology",Float32,
               ("longitude","latitude","month"),attrib=attr_var);
    v[:] = data[1][:,:,1:12];

    v = defVar(ds,"domain_monthly_std_climatology",Float32,
               ("longitude","latitude","month"),attrib=attr_var);
    v[:] = data[2][:,:,1:12];

    v = defVar(ds,"domain_monthly_maximum_climatology",Float32,
               ("longitude","latitude","month"),attrib=attr_var);
    v[:] = data[3][:,:,1:12];

    v = defVar(ds,"domain_monthly_minimum_climatology",Float32,
               ("longitude","latitude","month"),attrib=attr_var);
    v[:] = data[4][:,:,1:12];


    v = defVar(ds,"zonalavg_yearly_mean_climatology",Float32,
               ("latitude",),attrib=attr_var);
    v[:] = zdata[1][:,end];

    v = defVar(ds,"zonalavg_yearly_std_climatology",Float32,
               ("latitude",),attrib=attr_var);
    v[:] = zdata[2][:,end];

    v = defVar(ds,"zonalavg_yearly_maximum_climatology",Float32,
               ("latitude",),attrib=attr_var);
    v[:] = zdata[3][:,end];

    v = defVar(ds,"zonalavg_yearly_minimum_climatology",Float32,
               ("latitude",),attrib=attr_var);
    v[:] = zdata[4][:,end];


    v = defVar(ds,"zonalavg_monthly_mean_climatology",Float32,
               ("latitude","month"),attrib=attr_var);
    v[:] = zdata[1][:,1:12];

    v = defVar(ds,"zonalavg_monthly_std_climatology",Float32,
               ("latitude","month"),attrib=attr_var);
    v[:] = zdata[2][:,1:12];

    v = defVar(ds,"zonalavg_monthly_maximum_climatology",Float32,
               ("latitude","month"),attrib=attr_var);
    v[:] = zdata[3][:,1:12];

    v = defVar(ds,"zonalavg_monthly_minimum_climatology",Float32,
               ("latitude","month"),attrib=attr_var);
    v[:] = zdata[4][:,1:12];


    v = defVar(ds,"meridionalavg_yearly_mean_climatology",Float32,
               ("longitude",),attrib=attr_var);
    v[:] = mdata[1][:,end];

    v = defVar(ds,"meridionalavg_yearly_std_climatology",Float32,
               ("longitude",),attrib=attr_var);
    v[:] = mdata[2][:,end];

    v = defVar(ds,"meridionalavg_yearly_maximum_climatology",Float32,
               ("longitude",),attrib=attr_var);
    v[:] = mdata[3][:,end];

    v = defVar(ds,"meridionalavg_yearly_minimum_climatology",Float32,
               ("longitude",),attrib=attr_var);
    v[:] = mdata[4][:,end];


    v = defVar(ds,"meridionalavg_monthly_mean_climatology",Float32,
               ("longitude","month"),attrib=attr_var);
    v[:] = mdata[1][:,1:12];

    v = defVar(ds,"meridionalavg_monthly_std_climatology",Float32,
               ("longitude","month"),attrib=attr_var);
    v[:] = mdata[2][:,1:12];

    v = defVar(ds,"meridionalavg_monthly_maximum_climatology",Float32,
               ("longitude","month"),attrib=attr_var);
    v[:] = mdata[3][:,1:12];

    v = defVar(ds,"meridionalavg_monthly_minimum_climatology",Float32,
               ("longitude","month"),attrib=attr_var);
    v[:] = mdata[4][:,1:12];


    close(ds);

    @info "$(Dates.now()) - Analysed $(uppercase(ipar["name"])) data for RUN $irun has been saved into file $(afnc) and moved to the data directory $(afol)."

end
