
#=
For this module to work, you`ll need AWS credentials in the ${HOME}/.aws directory. 
=# 

using Printf
using YAML

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
    eachindex(instance_types) do i
        @printf("%20s: %5s cores %12s MiB of RAM\n", instance_types[i]["instanceType"], instance_types[i]["vCpuInfo"]["defaultVCpus"], instance_types[i]["memoryInfo"]["sizeInMiB"] )
    end
end

function configure_cluster(subnet, keyname, instance_type, min_count, max_count)    
    data = Dict(
        "Region" => "us-east-1",
        "Image" => Dict("Os" => "ubuntu2204"),
        "HeadNode" => Dict(
            "InstanceType" => instance_type,
            "Networking" => Dict("SubnetId" => subnet),
            "Ssh" => Dict("KeyName" => keyname)
        ),
        "Scheduling" => Dict(
            "Scheduler" => "slurm",
            "SlurmQueues" => [
                Dict(
                    "Name" => "queue1",
                    "ComputeResources" => [
                        Dict(
                            "Name" => instance_type,
                            "InstanceType" => instance_type,
                            "MinCount" => min_count,
                            "MaxCount" => max_count
                        ),
                        Dict(
                            "Name" => instance_type,
                            "InstanceType" => instance_type,
                            "MinCount" => min_count,
                            "MaxCount" => max_count
                        )
                    ],
                    "Networking" => Dict("SubnetIds" => ["subnet-b482218a"])
                )
            ]
        )
    )
    open("cluster.yaml", "w") do f
        write(f, yaml(data))
    end
end