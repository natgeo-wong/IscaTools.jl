

function iscastreamfunction(init::AbstractDict,iroot::AbstractDict)

    for irun = 1 : init["nruns"]
        @info "$(Dates.now()) - Calculating Zonal-Averaged MERIDIONAL STREAMFUNCTION for RUN $irun"
        iscacalcpsi(init,iroot,irun,init["sealp"])
    end

end

function iscacalcpsi(
    init::AbstractDict,iroot::AbstractDict,
    irun::Integer,sealp::Real
)

    @info "$(Dates.now()) - Extracting MERIDIONAL WIND and PRESSURE data ..."
    inc = iscarawname(iroot,irun=irun); ids = Dataset(inc);
    vwind = ids["vcomp"][:]*1
    pfull = ids["pfull"][:]*1
    phsfc = ids["phalf"][end]*1
    pfull = vcat(0,pfull/phsfc)
    psfc  = ids["ps"][:]*1
    lat = ids["lat"][:]*1;
    close(ids)

    @info "$(Dates.now()) - Reshape / Permutedims data for calculation ..."
    nlon,nlat,npre,nt = size(vwind);
    vwind = permutedims(dropdims(mean(vwind,dims=1),dims=1),[1,3,2]);
    psfc  = dropdims(mean(psfc,dims=1),dims=1)
    vpsi = zeros(nlat,nt,npre); vii = zeros(npre+1); psiii = zeros(npre+1)

    @info "$(Dates.now()) - Performing Numerical Integration ..."
    for it = 1 : nt, ilat = 1 : nlat

        for ipre = 1 : npre; vii[ipre+1] = vwind[ilat,it,ipre] end
        psiii .= cumul_integrate(pfull*psfc[ilat,it],vii)
        for ipre = 1 : npre
            vpsi[ilat,it,ipre] = psiii[ipre+1] * 2 * pi * 6378e3 .* cosd.(lat[ilat]) / 9.81
        end

    end

    @info "$(Dates.now()) - Saving MERIDIONAL STREAMFUNCTION data for RUN $irun ..."
    vpsi = permutedims(vpsi,[1,3,2]); iscasavepsi(vpsi,init,iroot,irun)

end

function iscasavepsi(
    vpsi::Array{<:Real,3},
    init::AbstractDict,iroot::AbstractDict,irun::Integer
)

    imod,ipar,itime = iscainitialize(init,modID="cpre",parID="psi_v");
    inc = iscacalcname(ipar,iroot,irun=irun);
    if isfile(inc)
        @info "$(Dates.now()) - Stale NetCDF file $(inc) detected.  Overwriting ..."
        rm(inc);
    end

    @debug "$(Dates.now()) - Creating NetCDF file $(afnc) for MERIDIONAL STREAMFUNCTION for RUN $irun ..."
    ds = Dataset(inc,"c");

    ds.dim["longitude"] = length(imod["lon"])
    ds.dim["latitude"] = length(imod["lat"])
    ds.dim["time"] = Inf
    ds.dim["phalf"] = length(imod["phalf"])
    ds.dim["pfull"] = length(imod["pfull"])

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

    nctime = defVar(ds,"time", Float64, ("time",), attrib = Dict(
        "long_name"      => itime["ncattribs"]["long_name"],
        "units"          => itime["ncattribs"]["units"],
        "cartesian_axis" => itime["ncattribs"]["cartesian_axis"],
        "calendar_type"  => itime["ncattribs"]["calendar_type"],
        "calendar"       => itime["ncattribs"]["calendar"],
        "bounds"         => itime["ncattribs"]["bounds"],
    ))

    ncphalf = defVar(ds,"phalf", Float64, ("phalf",), attrib = Dict(
        "long_name"      => "approx half pressure level",
        "units"          => "hPa",
        "cartesian_axis" => "Z",
        "positive"       => "down",
    ))

    ncpfull = defVar(ds,"pfull", Float64, ("pfull",), attrib = Dict(
        "long_name"      => "approx full pressure level",
        "units"          => "hPa",
        "cartesian_axis" => "Z",
        "positive"       => "down",
    ))

    nclon[:] = imod["lon"]
    nclat[:] = imod["lat"]
    nctime[:] = itime["raw"]
    ncphalf[:] = imod["phalf"]
    ncpfull[:] = imod["pfull"]

    v = defVar(ds,"psi_v",Float32,("latitude","pfull","time"),attrib = Dict(
        "long_name"     => "Meridional Streamfunction",
        "units"         => "kg/s",
        "scale_factor"  => 1e9,
        "cell_methods"  => "time: mean",
        "time_avg_info" => "average_T1,average_T2,average_DT",
    ))

    v[:] = vpsi; close(ds)

    @info "$(Dates.now()) - Saved MERIDIONAL STREAMFUNCTION data for RUN $irun into NetCDF file."

end
