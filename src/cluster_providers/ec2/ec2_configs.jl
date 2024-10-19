

function loadDefaults(_::Type{AmazonEC2}, ccconfig_dict)

    ec2_defaults_dict = Dict()

    for (k,v) in defaults_dict[Provider]
        ec2_defaults_dict[k] = v
    end

    for (k,v) in ccconfig_dict["ec2"]
        ec2_defaults_dict[k |> Symbol] = v
    end

    !haskey(ec2_defaults_dict, :imageid) && @warn "\"imageid\" parameter not configured"

    return ec2_defaults_dict
end