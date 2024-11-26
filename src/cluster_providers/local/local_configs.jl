

function loadDefaults(_::Type{Localhost}, ccconfig_dict)

    local_defaults_dict = Dict()

    for (k,v) in defaults_dict[Provider]
        local_defaults_dict[k] = v
    end

    for (k,v) in ccconfig_dict["local"]
        local_defaults_dict[k |> Symbol] = v
    end

    return local_defaults_dict
end