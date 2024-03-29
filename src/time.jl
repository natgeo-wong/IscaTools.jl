"""
This file contains functions that extract information on the timestep of the Isca model output
"""

function supportedcalendars()
    return ["no_calendar","thirty_day"]
end

function thirty2threesixty(tvec::Vector{<:Real},units::AbstractString)

    @info "$(Dates.now()) - The Isca \"THIRTY_DAY\" calendar corresponds to the \"360_DAY\" calendar in CF convention.  Converting date vector into DateTime360Day type so that it is recognizable by CFTime.jl"

    return timeencode(tvec,units,calendar="360_day")

end

function retrievetime(fnc::AbstractString)

    @warn "$(Dates.now()) - Isca Calendars may not be recognized by CF conventions and therefore it is necessary to manually convert the time-information, where applicable, into CF conventions so that it can be parsed by CFTime.jl"

    ds = Dataset(fnc); t = ds["time"][:]; tattr = ds["time"].attrib;
    tdict = Dict{AbstractString,AbstractString}()
    tinfo = Dict{AbstractString,Any}()

    tdict["units"] = tattr["units"];
    tdict["long_name"] = tattr["long_name"];
    tdict["cartesian_axis"] = tattr["cartesian_axis"];
    tdict["calendar_type"] = tattr["calendar_type"]
    tdict["calendar"] = tattr["calendar"]
    tdict["bounds"] = tattr["bounds"]

    cal = tattr["calendar"]; supcals = supportedcalendars()
    if sum(lowercase(cal).==supcals) == 0
        @warn "$(Dates.now()) - $cal is currently not supported in IscaTools.jl, which means that some of the functionalities of IscaTools.jl cannot be used.  Please submit an issue or a PR."
    end

    if cal == "THIRTY_DAY"; t = thirty2threesixty(t,tdict["units"]) end

    tinfo["calendar"] = tattr["calendar"]
    tinfo["nhr"] = 0; tinfo["ndy"] = 0;
    tinfo["time"] = t; nt = length(t);
    tinfo["raw"] = ds["time"][:]

    if nt > 1
          tstep = tinfo["raw"][2] - tinfo["raw"][1]
    else; tstep = tinfo["raw"][1] * 2
    end

    tinfo["ncattribs"] = tdict;

    if cal == "NO_CALENDAR"

        unit = split(tattr["units"]," since ")[1];
        if occursin("day",unit)
            if tstep < 1;  tinfo["nhr"] = 1 / tstep end
            tinfo["ndy"] = length(t) * tstep;
        elseif occursin("hour",unit)
            if tstep < 24; tinfo["nhr"] = 24 / tstep end
            tinfo["ndy"] = length(t) * tstep / 24;
        elseif  occursin("month",unit)
            tinfo["ndy"] = length(t) * tstep * 30;
        else
            error("$(Dates.now()) - IscaTools.jl requires that if your calendar was set to \"NO_CALENDAR\", you need to express the frequency at which you save your data in units of hours or days.")
        end

    else

        ttot = t[end] - t[1] + tstep; nhr = 24 / Dates.value(Hour(tstep))
        tinfo["ndy"] = Day(ttot); if nhr > 1; tinfo["nhr"] = nhr; end

    end

    if round(Int,tinfo["nhr"]) != tinfo["nhr"]; tinfo["nhr"] = 0; end

    if cal == "NOLEAP" && tinfo["ndy"] !== 365
        @error("$(Dates.now()) - IscaTools.jl requires that if your calendar was set to \"NOLEAP\" or \"JULIAN\", your output data $(BOLD("MUST")) be saved every $(BOLD("year (360 days)")).")
    elseif cal == "JULIAN" && sum(tinfo["ndy"] .== [365,366]) == 0
        @error("$(Dates.now()) - IscaTools.jl requires that if your calendar was set to \"NOLEAP\" or \"JULIAN\", your output data $(BOLD("MUST")) be saved every $(BOLD("year (360 days)")).")
    elseif cal == "THIRTY_DAY" && sum(tinfo["ndy"] .== [30,360]) == 0
        @error("$(Dates.now()) - IscaTools.jl requires that if your calendar was set to \"THIRTY_DAY\", your output data $(BOLD("MUST")) be saved every $(BOLD("month (30 days)")) or $(BOLD("year (360 days)")).")
    elseif cal == "NO_CALENDAR" && sum(tinfo["ndy"] .== [30,360]) == 0
        @warn "$(Dates.now()) - IscaTools.jl has detected that your calendar was set to \"NO_CALENDAR\", and that you did not save data every $(BOLD("month (30 days)")), or $(BOLD("year (360 days)")).  Therefore, IscaTools.jl will perform time-averaging operations over the length of the $(BOLD("entire run ($(tinfo["ndy"]) days)"))."
    end

    if tinfo["ndy"] == 30; tinfo["isyear"] = false; else; tinfo["isyear"] = true; end

    close(ds); return tinfo

end

function retrieveruns!(itime::AbstractDict,iroot::AbstractDict)

    fol = glob("run*",iroot["raw"]); nfol = length(fol);
    itime["nruns"] = nfol;

    if isdir(iroot["spinup"])
          fol = glob("run*",iroot["spinup"]); nfol = length(fol);
          itime["nspin"] = nfol;
    else; itime["nspin"] = 0;
    end

    return

end
