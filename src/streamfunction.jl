

function iscastreamfunction(init::AbstractDict,iroot::AbstractDict)

    for irun = 1 : init["nruns"]; iscacalcpsi(iroot,irun,init["sealp"]) end

end

function iscacalcpsi(iroot::AbstractDict,irun::Integer,sealp::Real)

    inc = iscarawname(iroot,irun=irun); ids = Dataset(inc);
    vwind = ids["vcomp"][:]*1; pfull = vcat(0,ids["pfull"][:]*1); lat = ids["lat"][:]*1;
    close(ids)

    nlon,nlat,npre,nt = size(vwind);
    vwind = permutdims(dropdims(mean(vwind,dims=1),dims=1),[1,3,2]);
    vpsi = zeros(nlat,nt,npre); vii = zeros(np+1); psiii = zeros(np+1)

    for it = 1 : nt, ilat = 1 : nlat

        for ipre = 1 : npre; vii[ip+1] = vwind[ilat,it,ipre] end
        psiii .= cumul_integrate(pfull,vii)
        for ipre = 1 : npre
            vpsi[ilat,it,:] = psiii[ipre+1] * 2 * pi .* cosd.(lat[ilat]) / 9.81
        end

    end

    vpsi = permutedims(vpsi,[1,3,2]); iscasavepsi(vpsi,iroot,irun)

end

function iscasavepsi(vpsi::Array{<:Real,4},iroot::AbstractDict,irun::Integer)

    inc = iscarawname(iroot,irun=irun); ids = Dataset(inc,"a");

    v = defVar(ids,"psi_v",Float32,("lat","pfull","time"),attrib = Dict(
        "long_name"     => "Meridional Streamfunction",
        "units"         => "kg/s",
        "scale_factor"  => 1e9,
        "missing_value" => 1.0e20,
        "_FillValue"    => 1.0e20,
        "cell_methods"  => "time: mean",
        "time_avg_info" => "average_T1,average_T2,average_DT",
    ))

    v[:] = vpsi; close(ids)

end
