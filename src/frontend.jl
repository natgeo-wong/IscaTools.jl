

function iscapre2lvl(pressure::Real,imod::AbstractDict)

    sigma = imod["levels"]; sealp = imod["sealp"];
    return argmin(abs.(sealp*sigma .- pressure))

end
