
#=
For this module to work, you`ll need AWS credentials in the ${HOME}/.aws directory. 
=# 

#=
1. Create placement group.
2. Create EFS Filesystem.
3. Create EC2 instances and attach them to the EFS.
=# 

using Random
using AWS: @service
@service Ec2 
@service Efs

#=
Estrutura para Armazenar as informações e função de criação do cluster
=#

struct Cluster
    name::String
    placement_group::String
    security_group_id::String
    efs_id::String
    cluster_nodes::Dict{String, String}
end

function create_cluster(cluster_name, instance_type, image_id, key_name, count)
    placement_group = create_placement_group(cluster_name)
    security_group_id = create_security_group(cluster_name, "Grupo $cluster_name")
    #efs_id = create_efs()
    cluster_nodes = create_instances(cluster_name, instance_type, image_id, key_name, count, placement_group, security_group_id)
    Cluster(cluster_name, placement_group, security_group_id, "", cluster_nodes)
end

function delete_cluster(cluster_handle::Cluster)
    delete_instances(cluster_handle.cluster_nodes)
    for instance in cluster_handle.cluster_nodes
        status = get_instance_status(instance[2])

        while status != "terminated"
            println("Waiting for instance to terminate...")
            sleep(5)
            status = get_instance_status(instance[2])
        end
    end
    # delete_efs(cluster_handle.efs_id)
    delete_security_group(cluster_handle.security_group_id)
    delete_placement_group(cluster_handle.placement_group)
end

#=
Grupo de Alocação
=#
function create_placement_group(name)
    params = Dict(
        "GroupName" => name, 
        "Strategy" => "cluster",
        "TagSpecification" => 
            Dict(
                "ResourceType" => "placement-group",
                "Tag" => [Dict("Key" => "cluster", "Value" => name),
                          Dict("Key" => "Name", "Value" => name)]
            )
        )
    Ec2.create_placement_group(params)["placementGroup"]["groupName"]
end

#=
Foi preciso editar as linhas 9556 e 9569 do arquivo ~/.julia/packages/AWS/3Zvz1/src/services/ec2.jl e trocar o valor de groupName para GroupName.
=#
function delete_placement_group(name)
    params = Dict("GroupName" => name)
    Ec2.delete_placement_group(name)
end

#=
Grupo de Segurança 
=#
function create_security_group(name, description)
    params = Dict(
        "TagSpecification" => 
            Dict(
                "ResourceType" => "security-group",
                "Tag" => [Dict("Key" => "cluster", "Value" => name),
                          Dict("Key" => "Name", "Value" => name)]
            )
    )
    id = Ec2.create_security_group(name, description, params)["groupId"]
    params = Dict(
        "GroupId" => id, 
        "CidrIp" => "0.0.0.0/0",
        "IpProtocol" => "tcp",
        "FromPort" => 22,
        "ToPort" => 22)
    Ec2.authorize_security_group_ingress(params)
    id
end

function delete_security_group(id)
    Ec2.delete_security_group(Dict("GroupId" => id))
end

#=
Instâncias
Foi preciso editar as linhas 29578 e 29598 do arquivo ~/.julia/packages/AWS/3Zvz1/src/services/ec2.jl e trocar o valor de clientToken para ClientToken.
Precisa usar no mínimo c6i.large.
=#

function create_instances(cluster_name, instance_type, image_id, key_name, count, placement_group, security_group_id)
    cluster_nodes = Dict()
    params = Dict(
        "InstanceType" => instance_type,
        "ImageId" => image_id,
        "KeyName" => key_name,
        "Placement" => Dict("GroupName" => placement_group),
        "SecurityGroupId" => [security_group_id],
        "TagSpecification" => 
            Dict(
                "ResourceType" => "instance",
                "Tag" => [Dict("Key" => "cluster", "Value" => cluster_name),
                          Dict("Key" => "Name", "Value" => "headnode") ]
            )
    )
    instances = Ec2.run_instances(1,1,params)
    cluster_nodes["headnode"] = instances["instancesSet"]["item"]["instanceId"]

    worker_count = count - 1
    if worker_count > 1
        params["TagSpecification"]["Tag"][2]["Value"] = "worker"
        instances = Ec2.run_instances(worker_count,worker_count,params)
        for i in 1:worker_count
            instance = instances["instancesSet"]["item"][i]
            instance_id = instance["instanceId"]
            cluster_nodes["worker$i"] = instance_id
        end
    elseif worker_count == 1
        params["TagSpecification"]["Tag"][2]["Value"] = "worker"
        instances = Ec2.run_instances(worker_count,worker_count,params)
        instance = instances["instancesSet"]["item"]
        instance_id = instance["instanceId"]
        cluster_nodes["worker1"] = instance_id
    else
        return cluster_nodes
    end
    cluster_nodes
end

function delete_instances(cluster_nodes)
    for id in values(cluster_nodes)
        Ec2.terminate_instances(id)
    end
end

function get_instance_status(id)
    status = Ec2.describe_instances(Dict("InstanceId" => id))
    status["reservationSet"]["item"]["instancesSet"]["item"]["instanceState"]["name"]
end
#=
Sistema de Arquivo Compartilhado
=#
function create_efs()
    chars = ['a':'z'; 'A':'Z'; '0':'9']
    creation_token = join(chars[Random.rand(1:length(chars), 64)])
    Efs.create_file_system(creation_token)["FilesystemId"]
end

function delete_efs(id)
    Efs.delete_file_system(id)
end

