"""
Este modulo irá usar uma abordagem diferente. No lugar de tentar usar o CloudFormation,
vamos criar processos para executar o comando pcluster.
"""

using JSON
using YAML
using Random

using AWS: @service
@service Ec2 

"""
    Função para invocar pcluster
"""
function pcluster(commands)
    virtualenv = "source ~/apc-ve/bin/activate; pcluster $commands;"
    output = read(`bash -c $virtualenv`, String)
    JSON.parse(output)
end

using YAML

function configure_cluster(region, os, instance_type, subnet_id, key_name, resource_name, min_count, max_count)
    config = Dict(
        "Region" => region,
        "Image" => Dict("Os" => os),
        "HeadNode" => Dict(
            "InstanceType" => instance_type,
            "Networking" => Dict("SubnetId" => subnet_id),
            "Ssh" => Dict("KeyName" => key_name)
        ),
        "Scheduling" => Dict(
            "Scheduler" => "slurm",
            "SlurmQueues" => [
                Dict(
                    "Name" => "queue1",
                    "ComputeResources" => [
                        Dict(
                            "Name" => resource_name,
                            "Instances" => [Dict("InstanceType" => instance_type)],
                            "MinCount" => min_count,
                            "MaxCount" => max_count
                        )
                    ],
                    "Networking" => Dict("SubnetIds" => [subnet_id])
                )
            ]
        )
    )
    
    cluster_name = "cluster$(lowercase(randstring(10)))"
    filename = cluster_name * ".yaml"
    YAML.write_file(filename, config)

    cluster_name
end

function create_cluster(cluster_name)
    pcluster("create-cluster --dryrun true -c $cluster_name.yaml -n $cluster_name")
end

function delete_cluster(cluster_name)
    pcluster("delete $cluster_name")
    rm(cluster_name * ".yaml")
end

