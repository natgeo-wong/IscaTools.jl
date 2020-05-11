

iscancread(ncname::AbstractString,fol::AbstractString="") = Dataset(joinpath(fol,ncname))

function iscarawfolder(iroot::AbstractDict;irun::Integer)

    return joinpath(iroot["raw"],"run$(@sprintf("%04d",irun))")

end

function iscarawname(iroot::AbstractDict;irun::Integer)

    return joinpath(iroot["raw"],"run$(@sprintf("%04d",irun))",iroot["fname"])

end

function iscarawread(ipar::AbstractDict,iroot::AbstractDict;irun::Integer)

    inc = iscarawname(iroot;irun=irun); ids = iscancread(inc)
    return ids,ids[ipar["ID"]]

end

function iscaanafolder(ipar::AbstractDict,iroot::AbstractDict)

    if ipar["level"] == "sfc";

        fol = joinpath(iroot["ana"],ipar["ID"]);
        if !isdir(fol)
            @info "$(Dates.now()) - The folder for analyzed $(uppercase(ipar["ID"])) data does not exist.  Creating now ..."
            mkpath(fol);
        end

    else

        phPa = "$(ipar["ID"])-lvl$(@sprintf("%02d",ipar["level"]))"
        fol = joinpath(iroot["ana"],ipar["ID"],phPa);
        if !isdir(fol)
            @info "$(Dates.now()) - The folder for analyzed $(uppercase(ipar["ID"])) data at σ-level $(ipar["level"]) does not exist.  Creating now ..."
            mkpath(fol);
        end

    end

    return fol
end

function iscaananame(ipar::AbstractDict;irun::Integer)

    if ipar["level"] != "sfc"
          fname = "$(ipar["ID"])-lvl$(@sprintf("%02d",ipar["level"]))";
    else; fname = "$(ipar["ID"])-sfc";
    end

    return "$(fname)-run$(@sprintf("%04d",irun)).nc"

end

function iscaanaread(
    ID::AbstractString,
    ipar::AbstractDict,iroot::AbstractDict;
    irun::Integer
)

    ibase = iscaanafol(ipar,iroot)
    inc = iscaananame(ipar;irun=irun);
    ids = iscancread(inc,ibase)
    return ids,ids[ID]

end

function iscapre2lvl(pressure::Real,imod::AbstractDict)

    return argmin(abs.(imod["levels"] .- pressure))

end

function putinfo(imod::Dict,ipar::Dict,itime::Dict,iroot::Dict)

    rfol = pwd();
    cd(iscaanafolder(ipar,iroot)); @save "info_par.jld2" imod ipar;
    cd(iroot["ana"]); @save "info_time.jld2" itime;
    cd(rfol);

end
