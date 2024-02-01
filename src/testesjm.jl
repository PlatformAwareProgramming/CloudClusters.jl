
#=
For this module to work, you`ll need AWS credentials in the ${HOME}/.aws directory. 
=# 

using Printf
using YAML
using Random

using AWS: @service
@service Ec2 
@service S3

export retrieve_instance_types
export print_info

#=
    This function creates a random bucket in the default region.
    It returns the name of the bucket.
=#
function create_random_bucket()
    bucket_name = "bucket$(lowercase(randstring(10)))"
    S3.create_bucket(bucket_name)
    bucket_name
end

#=
    This function puts a template file in a bucket.
    It returns the url of the object.
=#
function put_template_bucket(template_file, bucket_name)
    open(template_file, "r") do file
        S3.put_object(bucket_name, "template.yaml", Dict("body" => read(file, String)))
    end
    url = "s3://" * bucket_name * "/" * "template.yaml"
    url
end

function delete_random_bucket(bucket_name)
    S3.delete_object(bucket_name, "template.yaml")
    S3.delete_bucket(bucket_name)
end

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
    for i in eachindex(instance_types)
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