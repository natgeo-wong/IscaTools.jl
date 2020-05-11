

function iscastreamfunction(init::AbstractDict,iroot::AbstractDict)

    for irun = 1 : init["nruns"]
        @info "$(Dates.now()) - Calculating Zonal-Averaged Meridional Streamfunction for RUN $irun"
        iscacalcpsi(iroot,irun,init["sealp"])
    end

end

function iscacalcpsi(iroot::AbstractDict,irun::Integer,sealp::Real)

    @info "$(Dates.now()) - Extracting Meridional Wind and Pressure data ..."
    inc = iscarawname(iroot,irun=irun); ids = Dataset(inc);
    vwind = ids["vcomp"][:]*1; pfull = vcat(0,ids["pfull"][:]*100); lat = ids["lat"][:]*1;
    close(ids)

    @info "$(Dates.now()) - Reshape / Permutedims data for calculation ..."
    nlon,nlat,npre,nt = size(vwind);
    vwind = permutedims(dropdims(mean(vwind,dims=1),dims=1),[1,3,2]);
    vpsi = zeros(nlat,nt,npre); vii = zeros(npre+1); psiii = zeros(npre+1)

    @info "$(Dates.now()) - Performing Numerical Integration over Pressure Levels ..."
    for it = 1 : nt, ilat = 1 : nlat

        for ipre = 1 : npre; vii[ipre+1] = vwind[ilat,it,ipre] end
        psiii .= cumul_integrate(pfull,vii)
        for ipre = 1 : npre
            vpsi[ilat,it,ipre] = psiii[ipre+1] * 2 * pi * 6378e3 .* cosd.(lat[ilat]) / 9.81
        end

    end

    @info "$(Dates.now()) - Saving Meridional Streamfunction data ..."
    vpsi = permutedims(vpsi,[1,3,2]); iscasavepsi(vpsi,iroot,irun)

end

function iscasavepsi(vpsi::Array{<:Real,3},iroot::AbstractDict,irun::Integer)

    inc = iscarawname(iroot,irun=irun); ids = Dataset(inc,"a");

    v = defVar(ids,"psi_v",Float32,("lat","pfull","time"),attrib = Dict(
        "long_name"     => "Meridional Streamfunction",
        "units"         => "kg/s",
        "scale_factor"  => 1e9,
        "cell_methods"  => "time: mean",
        "time_avg_info" => "average_T1,average_T2,average_DT",
    ))

    v[:] = vpsi; close(ids)

end
