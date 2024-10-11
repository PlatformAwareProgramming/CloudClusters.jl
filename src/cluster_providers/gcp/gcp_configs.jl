

function readCCConfig(_::Type{GoogleCloud})
    readCCConfig("CCconfig.GCP.toml")
end

function loadDefaults(_::Type{GoogleCloud}, ccconfig_dict)

    gcp_defaults_dict = Dict()

    gcp_defaults_dict[:imageid] = ccconfig_dict["defaults"]["imageid"]
     
    if haskey(ccconfig_dict["defaults"],"subnet_id")
        gcp_defaults_dict[:subnet_id] = ccconfig_dict["defaults"]["subnet_id"]
    end
    
    if haskey(ccconfig_dict["defaults"],"security_group_id")
        gcp_defaults_dict[:security_group_id] = ccconfig_dict["defaults"]["security_group_id"]
    end
    if haskey(ccconfig_dict["defaults"],"placement_group")
        gcp_defaults_dict[:placement_group] = ccconfig_dict["defaults"]["placement_group"] 
    end

    return gcp_defaults_dict
end