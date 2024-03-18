
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
using Serialization
using Base64
@service Ec2 
@service Efs

#=
Estrutura para Armazenar as informações e função de criação do cluster
=#

struct Cluster
    name::String
    placement_group::String
    security_group_id::String
    file_system_id::String
    cluster_nodes::Dict{String, String}
end

function create_cluster(cluster_name, instance_type, image_id, key_name, count)
    # Eu vou recuperar a primeira subrede e utilizá-la. Na prática não faz diferença, mas podemos depois criar uma função para escolher a subrede e VPC.
    subnet_id = Ec2.describe_subnets()["subnetSet"]["item"][1]["subnetId"]
    println("Subnet ID: $subnet_id")
    placement_group = create_placement_group(cluster_name)
    println("Placement Group: $placement_group")
    security_group_id = create_security_group(cluster_name, "Grupo $cluster_name")
    println("Security Group ID: $security_group_id")
    file_system_id = create_efs(subnet_id, security_group_id)
    println("File System ID: $file_system_id")
    file_system_ip = get_mount_target_ip(file_system_id)
    println("File System IP: $file_system_ip")
    cluster_nodes = create_instances(cluster_name, instance_type, image_id, key_name, count, placement_group, security_group_id, subnet_id,file_system_ip)
    Cluster(cluster_name, placement_group, security_group_id, file_system_id, cluster_nodes)
end

function get_ips(c)
    ips = Dict()
    for (node, id) in c.cluster_nodes
        public_ip = Ec2.describe_instances(Dict("InstanceId" => id))["reservationSet"]["item"]["instancesSet"]["item"]["ipAddress"]
        private_ip = Ec2.describe_instances(Dict("InstanceId" => id))["reservationSet"]["item"]["instancesSet"]["item"]["privateIpAddress"]
        ips[node]=Dict("public_ip" => public_ip, "private_ip" => private_ip)
    end
    ips
end

function delete_cluster(cluster_handle::Cluster)
    delete_instances(cluster_handle.cluster_nodes)
    for instance in cluster_handle.cluster_nodes
        status = get_instance_status(instance[2])
        while status != "terminated"
            println("Waiting for instances to terminate...")
            sleep(5)
            status = get_instance_status(instance[2])
        end
    end
    delete_efs(cluster_handle.file_system_id)
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
    sg_name =  Ec2.describe_security_groups(Dict("GroupId" => id))["securityGroupInfo"]["item"]["groupName"]
    params = Dict(
        "GroupId" => id, 
        "SourceSecurityGroupName" => sg_name)
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

function create_instances(cluster_name, instance_type, image_id, key_name, count, placement_group, security_group_id, subnet_id, file_system_ip)
    cluster_nodes = Dict()
    user_data = "#!/bin/bash
apt-get -y install nfs-common
mkdir /home/ubuntu/shared/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $file_system_ip:/ /home/ubuntu/shared/
chown -R ubuntu:ubuntu /home/ubuntu/shared
"
    user_data_base64 = base64encode(user_data)
    params = Dict(
        "InstanceType" => instance_type,
        "ImageId" => image_id,
        "KeyName" => key_name,
        "Placement" => Dict("GroupName" => placement_group),
        "SecurityGroupId" => [security_group_id],
        "SubnetId" => subnet_id,
        "TagSpecification" => 
            Dict(
                "ResourceType" => "instance",
                "Tag" => [Dict("Key" => "cluster", "Value" => cluster_name),
                          Dict("Key" => "Name", "Value" => "headnode") ]
            ),
        "UserData" => user_data_base64,
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
    description = Ec2.describe_instances(Dict("InstanceId" => id))
    description["reservationSet"]["item"]["instancesSet"]["item"]["instanceState"]["name"]
end

function get_instance_subnet(id)
    description = Ec2.describe_instances(Dict("InstanceId" => id))
    description["reservationSet"]["item"]["instancesSet"]["item"]["subnetId"]
end

#=
Sistema de Arquivo Compartilhado
=#

function create_efs(subnet_id, security_group_id)
    chars = ['a':'z'; 'A':'Z'; '0':'9']
    creation_token = join(chars[Random.rand(1:length(chars), 64)])
    file_system_id = Efs.create_file_system(creation_token)["FileSystemId"]
    create_mount_point(file_system_id, subnet_id, security_group_id)
    file_system_id
end

function create_mount_point(file_system_id, subnet_id, security_group_id)
    params = Dict(
        "SecurityGroups" => [security_group_id]
    )

    status = Efs.describe_file_systems(Dict("FileSystemId" => file_system_id))["FileSystems"][1]["LifeCycleState"]
    while status != "available"
        println("Waiting for File System to be available...")
        sleep(5)
        status = Efs.describe_file_systems(Dict("FileSystemId" => file_system_id))["FileSystems"][1]["LifeCycleState"]
    end
    println("Creating Mount Target...")

    mount_target_id = Efs.create_mount_target(file_system_id, subnet_id, params)["MountTargetId"]
    status = Efs.describe_mount_targets(Dict("MountTargetId" => mount_target_id))["MountTargets"][1]["LifeCycleState"]
    while status != "available"
        println("Waiting for mount target to be available...")
        sleep(5)
        status = Efs.describe_mount_targets(Dict("MountTargetId" => mount_target_id))["MountTargets"][1]["LifeCycleState"]
    end
    mount_target_id
end

function get_mount_target_ip(file_system_id)
    mount_target_id = Efs.describe_mount_targets(Dict("FileSystemId" => file_system_id))["MountTargets"][1]["MountTargetId"]
    ip = Efs.describe_mount_targets(Dict("MountTargetId" => mount_target_id))["MountTargets"][1]["IpAddress"]
    ip
end

function delete_efs(file_system_id)
    for mount_target in Efs.describe_mount_targets(Dict("FileSystemId" => file_system_id))["MountTargets"]
        Efs.delete_mount_target(mount_target["MountTargetId"])
    end
    while length(Efs.describe_mount_targets(Dict("FileSystemId" => file_system_id))["MountTargets"]) != 0
        println("Waiting for mount targets to be deleted...")
        sleep(5)
    end
    Efs.delete_file_system(file_system_id)
end

