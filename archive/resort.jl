"""
This file contains all the functions in ClimateIsca.jl that resorts the Isca GCM output and resaves
into NetCDF files grouped according to parameter/variables and resaved by year.

"""

function iscaresort(parvec,iroot::Dict)

    @info "$(Dates.now()) - Resorting the following Isca GCM output variables ..."
    pinfo = iscaparload(parvec);
    for ii = 1 : size(pinfo,1); @info "$(Dates.now()) - $(ii)) $(pinfo[ii,3]) | $(pinfo[ii,4])" end

    fol,fname = iscadinfo(iroot["raw"]); ndir = length(fol);

    pf  = ncread(fname,"pfull"); ph = ncread(fname,"phalf"); np = length(pf);
    lon = ncread(fname,"lon"); nlon = length(lon);
    lat = ncread(fname,"lat"); nlat = length(lat);
    tinfo,nt = iscatime(fname); dim = [nlon,nlat,nt];

    ncattr = Dict("fullpre"=>pf,"halfpre"=>ph,"nlevels"=>np,"dimensions"=>dim,
                  "longitude"=>lon,"latitude"=>lat,
                  "timestep"=>tinfo["dt"],"timespan"=>tinfo["span"]);

    for yr = 1 : ndir; cd(joinpath(iroot["raw"],fol[yr]))

        for par in parvec; pinfo = iscaparameter(par)

            pdata = iscaparncread(fname,pinfo,ncattr);
                    iscaparncsave(pdata,pinfo,ncattr,yr,iroot["data"]);

        end

    end

    cd(iroot["isca"]); @save "isca_info.jld2" ncattr;

end
