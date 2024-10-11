

function readCCConfig(_::Type{AmazonEC2})
    readCCConfig("CCconfig.EC2.toml")
end

function loadDefaults(_::Type{AmazonEC2}, ccconfig_dict)

    ec2_defaults_dict = Dict()

    ec2_defaults_dict[:imageid] = ccconfig_dict["defaults"]["imageid"]
    
    if haskey(ccconfig_dict["defaults"],"subnet_id")
        ec2_defaults_dict[:subnet_id] = ccconfig_dict["defaults"]["subnet_id"]
    end
    
    if haskey(ccconfig_dict["defaults"],"security_group_id")
        ec2_defaults_dict[:security_group_id] = ccconfig_dict["defaults"]["security_group_id"]
    end
    if haskey(ccconfig_dict["defaults"],"placement_group")
        ec2_defaults_dict[:placement_group] = ccconfig_dict["defaults"]["placement_group"] 
    end

    return ec2_defaults_dict
end