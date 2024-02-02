
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

"""
    Função para invocar pcluster
"""
function pcluster(commands)
    virtualenv = "source ~/apc-ve/bin/activate; pcluster $commands;"
    process = `bash -c $virtualenv`
    run(process)
end

"""
    This function creates a random bucket in the default region.
    It returns the name of the bucket.
"""
function create_random_bucket()
    bucket_name = "bucket$(lowercase(randstring(10)))"
    S3.create_bucket(bucket_name)
    bucket_name
end

"""
    This function puts a template file in a bucket.
    It returns the url of the object.
"""
function put_template_bucket(template_file, bucket_name)
    open(template_file, "r") do file
        S3.put_object(bucket_name, "template.yaml", Dict("body" => read(file, String)))
    end
    url = "s3://" * bucket_name * "/" * "template.yaml"
    url
end

"""
    This function removes bucket. To do so, it must first
    remote all the files. Then, it can remove the bucket.
"""
function delete_random_bucket(bucket_name)
    S3.delete_object(bucket_name, "template.yaml")
    S3.delete_bucket(bucket_name)
end

"""
    create_cluster(region, instance_type, subnet_id, key_name, min_count, max_count)
        1. Loads the example template.
        2. Customize it and save it to a random file.
        3. Creates the bucket.
        4. Upload the random template file to the bucket.
        5. Creates the CloudFormation stack based on the template.
        6. Removes the random bucket.
        7. Returns the stack Id and the IP?

"""
function create_cluster(instance_type, subnet_id, key_name, min_count, max_count)
    template = YAML.load_file("artifacts/cluster-template.yaml")
    template["Resources"]["HeadNodeLaunchTemplate"]["Properties"]["LaunchTemplateData"]["InstanceType"] = instance_type
    template["Resources"]["HeadNodeLaunchTemplate"]["Properties"]["LaunchTemplateData"]["KeyName"] = key_name

    template["Resources"]["HeadNode"]["Properties"]["Networking"]["SubnetId"] = subnet_id
    
    template["Resources"]["ComputeNode"]["Properties"]["MinCount"] = min_count
    template["Resources"]["ComputeNode"]["Properties"]["MaxCount"] = max_count
    
    open("random.yaml", "w") do file
        write(file, YAML.dump(template))
    end

    bucket_name = create_random_bucket()
    url = put_template_bucket("random.yaml", bucket_name)

    #=
    stack_id = CloudFormation.create_stack(region, url)
    delete_random_bucket(bucket_name)

    stack_id
    =#
end

"""
    This function should destroy the cluster using the CloudFormation service.
"""
function delete_cluster(stack_id)
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