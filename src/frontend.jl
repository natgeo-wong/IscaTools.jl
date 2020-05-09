

iscancread(ncname::AbstractString,fol::AbstractString="") = Dataset(joinpath(fol,ncname))

function iscarawfolder(iroot::AbstractDict;run::Integer)

    return joinpath(iroot["raw"],"run$(@sprintf("%04d",run))")

end

function iscarawname(iroot::AbstractDict;run::Integer)

    return joinpath(iroot["raw"],"run$(@sprintf("%04d",run))",iroot["fname"])

end

function iscarawread(ipar::AbstractDict,iroot::AbstractDict;run::Integer)

    inc = iscarawname(iroot;run=run); ids = iscancread(inc)
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
        fol = joinpath(iroot["ana"],epar["ID"],phPa);
        if !isdir(fol)
            @info "$(Dates.now()) - The folder for analyzed $(uppercase(ipar["ID"])) data at σ-level $(ipar["level"]) does not exist.  Creating now ..."
            mkpath(fol);
        end

    end

    return fol
end

function iscaananame(ipar::AbstractDict;run::Integer)

    if ipar["level"] != "sfc"
          fname = "$(ipar["ID"])-lvl$(@sprintf("%02d",ipar["level"]))";
    else; fname = "$(ipar["ID"])-sfc";
    end

    return "$(fname)-run$(@sprintf("%04d",run)).nc"

end

function iscaanaread(
    ID::AbstractString,
    ipar::AbstractDict,iroot::AbstractDict;
    run::Integer
)

    ibase = iscaanafol(ipar,iroot)
    inc = iscaananame(ipar;run=run);
    ids = iscancread(inc,ibase)
    return ids,ids[ID]

end

function iscapre2lvl(pressure::Real,imod::AbstractDict)

    sigma = imod["levels"]; sealp = imod["sealp"];
    return argmin(abs.(sealp*sigma .- pressure))

end
