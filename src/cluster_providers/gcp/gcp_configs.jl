

function loadDefaults(_::Type{GoogleCloud}, ccconfig_dict)

    gcp_defaults_dict = Dict()

    for (k,v) in defaults_dict[Provider]
        gcp_defaults_dict[k] = v
    end

    for (k,v) in ccconfig_dict["gcp"]
        gcp_defaults_dict[k |> Symbol] = v
    end

    return gcp_defaults_dict
end