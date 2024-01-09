module CloudClusters
#=
For this module to work, you`ll need AWS credentials in the ${HOME}/.aws directory. 
=# 

using Printf
using AWS: @service
@service Ec2

export retrieve_instance_types
export print_info

function retrieve_instance_types()
    response = Ec2.describe_instance_types()
    instance_types = response["instanceTypeSet"]["item"]

    while haskey(response, "nextToken")
        nextToken = response["nextToken"]
        params = Dict("NextToken" => nextToken)
        response = Ec2.describe_instance_types(params)
        instance_types = vcat(instance_types, response["instanceTypeSet"]["item"])
    end
    instance_types
end

function print_info()
    instance_types = retrieve_instance_types()
    for i in 1:length(instance_types)
        @printf("%20s: %5s cores %12s MiB of RAM\n", instance_types[i]["instanceType"], instance_types[i]["vCpuInfo"]["defaultVCpus"], instance_types[i]["memoryInfo"]["sizeInMiB"] )
    end
end

end # end CloudCluster