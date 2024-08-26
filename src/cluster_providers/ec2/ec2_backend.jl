
#=
For this module to work, you`ll need AWS credentials in the ${HOME}/.aws directory. 
=# 

#=
1. Create placement group.
2. Create EFS Filesystem.
3. Create EC2 instances and attach them to the EFS.
=# 

using AWS
println("Adaptando o código do Módulo AWS.jl...")
using FilePathsBase
aws_package_dir = ENV["HOME"] * "/.julia/packages/AWS"
all_entries = readdir(aws_package_dir)
subdirs = filter(entry -> isdir(joinpath(aws_package_dir, entry)), all_entries)

for subdir in subdirs
    ec2_file = joinpath(aws_package_dir, subdir, "src", "services", "ec2.jl")
    chmod(ec2_file, 0o644)
    content = read(ec2_file, String)
    new_content = replace(content, "Dict{String,Any}(\"groupName\" => groupName);" => "Dict{String,Any}(\"GroupName\" => groupName);")
    new_content = replace(new_content, "\"MaxCount\" => MaxCount, \"MinCount\" => MinCount, \"clientToken\" => string(uuid4())" => 
                                       "\"MaxCount\" => MaxCount, \"MinCount\" => MinCount, \"ClientToken\" => string(uuid4())")
    new_content = replace(new_content, "\"clientToken\" => string(uuid4())" =>  "\"ClientToken\" => string(uuid4())")
    open(ec2_file, "w") do io
        write(io, new_content)
    end
end

using Random
using AWS: @service
using Serialization
using Base64
using Sockets
@service Ec2 
@service Efs

#=
Como utilizar. Escolher uma das quatro opções abaixo.
cluster = ManagerWorkersWithoutSharedFS("pargocad", "c6i.large", "c6i.large", 4, "jmhal", "ami-04b70fa74e45c3917", nothing, nothing)
cluster = PeersWorkersWithoutSharedFS("pargocad", "c6i.large", 4, "jmhal", "ami-04b70fa74e45c3917", nothing, nothing)
cluster = ManagerWorkersWithSharedFS("pargocad", "c6i.large", "c6i.large", 4,"jmhal", "ami-04b70fa74e45c3917", nothing, nothing)
cluster = PeersWorkersWithSharedFS("pargocad", "c6i.large", 4, "jmhal", "ami-04b70fa74e45c3917", nothing, nothing)

Depois:
cluster_handle = create_cluster(cluster)
get_ips_instance(cluster_handle.cluster_nodes["peer1"]) ou get_ips_instance(cluster_handle.cluster_nodes["headnode"]) para pegar os IPs.

Finalmente:
delete_cluster(cluster_handle)
=#

#=
Estrutura para Armazenar as informações e função de criação do cluster
=#

mutable struct SharedFSInfo 
    file_system_id::String  
    file_system_ip::String
end

abstract type Cluster end

mutable struct ManagerWorkersCluster <: Cluster
    name::String
    instance_type_master::String
    instance_type_worker::String
    count::Int
    key_name_master::String
    key_name_worker::String
    image_id_master::String
    image_id_worker::String
    subnet_id::Union{String, Nothing}
    placement_group::Union{String, Nothing}
    auto_pg::Bool
    security_group_id::Union{String, Nothing}
    auto_sg::Bool
    environment::Union{SharedFSInfo, Nothing}
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    shared_fs::Bool
end


mutable struct PeerWorkersCluster <: Cluster
    name::String
    instance_type::String
    count::Int
    key_name::String
    image_id::String
    subnet_id::Union{String, Nothing}
    placement_group::Union{String, Nothing}
    auto_pg::Bool
    security_group_id::Union{String,Nothing}
    auto_sg::Bool
    environment::Union{SharedFSInfo, Nothing}
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    shared_fs::Bool
end

function create_cluster(cluster::Cluster)
 
    if cluster.shared_fs
        file_system_id = create_efs(cluster.subnet_id, cluster.security_group_id)
        println("File System ID: $file_system_id")
        file_system_ip = get_mount_target_ip(file_system_id)
        println("File System IP: $file_system_ip")
        cluster.environment = SharedFSInfo(file_system_id, file_system_ip)
    end

    cluster.cluster_nodes = create_instances(cluster)
    cluster
end


function get_ips(cluster_handle::Cluster)
    ips = Dict()
    for (node, id) in cluster_handle.cluster_nodes
        public_ip = Ec2.describe_instances(Dict("InstanceId" => id))["reservationSet"]["item"]["instancesSet"]["item"]["ipAddress"]
        private_ip = Ec2.describe_instances(Dict("InstanceId" => id))["reservationSet"]["item"]["instancesSet"]["item"]["privateIpAddress"]
        ips[node]=Dict(:public_ip => public_ip, :private_ip => private_ip)
    end
    ips
end

function get_ips_instance(instance_id::String)
    public_ip = Ec2.describe_instances(Dict("InstanceId" => instance_id))["reservationSet"]["item"]["instancesSet"]["item"]["ipAddress"]
    private_ip = Ec2.describe_instances(Dict("InstanceId" => instance_id))["reservationSet"]["item"]["instancesSet"]["item"]["privateIpAddress"]
    Dict(:public_ip => public_ip, :private_ip => private_ip)
end

function delete_cluster(cluster::Cluster)
    delete_instances(cluster.cluster_nodes)
    for instance in cluster.cluster_nodes
        status = get_instance_status(instance[2])
        while status != "terminated"
            println("Waiting for instances to terminate...")
            sleep(5)
            status = get_instance_status(instance[2])
        end
    end
    
    cluster.shared_fs && delete_efs(cluster.file_system_id)
    cluster.auto_sg && delete_security_group(cluster.security_group_id)
    cluster.auto_pg && delete_placement_group(cluster.placement_group)

    return
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

function delete_placement_group(name)
    params = Dict("GroupName" => name)
    Ec2.delete_placement_group(name)
end

#=
Grupo de Segurança 
=#
function create_security_group(name, description)
    # Criamos o grupo
    params = Dict(
        "TagSpecification" => 
            Dict(
                "ResourceType" => "security-group",
                "Tag" => [Dict("Key" => "cluster", "Value" => name),
                          Dict("Key" => "Name", "Value" => name)]
            )
    )
    id = Ec2.create_security_group(name, description, params)["groupId"]

    # Liberamos o SSH.
    params = Dict(
        "GroupId" => id, 
        "CidrIp" => "0.0.0.0/0",
        "IpProtocol" => "tcp",
        "FromPort" => 22,
        "ToPort" => 22)
    Ec2.authorize_security_group_ingress(params)

    # Liberamos o tráfego interno do grupo.
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
Criação de Instâncias
=# 

# Funções auxiliares.
function set_up_ssh_connection(cluster_name)                    
   # Criar chave interna pública e privada do SSH.
   chars = ['a':'z'; 'A':'Z'; '0':'9']
   random_suffix = join(chars[Random.rand(1:length(chars), 5)])
   internal_key_name = cluster_name * random_suffix
   run(`ssh-keygen -f /tmp/$internal_key_name -N ""`)
   private_key = base64encode(read("/tmp/$internal_key_name", String))
   public_key = base64encode(read("/tmp/$internal_key_name.pub", String))
  
   # Define o script que irá instalar a chave pública e privada no headnode e workers.
   user_data = "#!/bin/bash
echo $private_key | base64 -d > /home/ubuntu/.ssh/$cluster_name
echo $public_key | base64 -d > /home/ubuntu/.ssh/$cluster_name.pub
echo 'Host *
   IdentityFile /home/ubuntu/.ssh/$cluster_name
   StrictHostKeyChecking no' > /home/ubuntu/.ssh/config
cat /home/ubuntu/.ssh/$cluster_name.pub >> /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu.ubuntu /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/*
"
   [internal_key_name, user_data]
end

function create_params(cluster::ManagerWorkersCluster, user_data_base64)
   params_master = Dict(
        "InstanceType" => cluster.instance_type_master,
        "ImageId" => cluster.image_id_master,
        "KeyName" => cluster.key_name_master,
        "TagSpecification" => 
            Dict(
                "ResourceType" => "instance",
                "Tag" => [Dict("Key" => "cluster", "Value" => cluster.name),
                          Dict("Key" => "Name", "Value" => "master") ]
            ),
        "UserData" => user_data_base64,
    )

    params_workers = Dict(
        "InstanceType" => cluster.instance_type_worker,
        "ImageId" => cluster.image_id_worker,
        "KeyName" => cluster.key_name_worker,
        "TagSpecification" => 
            Dict(
                "ResourceType" => "instance",
                "Tag" => [Dict("Key" => "cluster", "Value" => cluster.name),
                          Dict("Key" => "Name", "Value" => "worker") ]
            ),
        "UserData" => user_data_base64,
    )

    if !isnothing(cluster.subnet_id)
        params_master["SubnetId"] = cluster.subnet_id
        params_workers["SubnetId"] = cluster.subnet_id
    end

    if !isnothing(cluster.placement_group)
        params_master["Placement"] = Dict("GroupName" => cluster.placement_group)
        params_workers["Placement"] = Dict("GroupName" => cluster.placement_group)
    end

    if !isnothing(cluster.security_group_id)
        params_master["SecurityGroupId"] = [cluster.security_group_id]
        params_workers["SecurityGroupId"] = [cluster.security_group_id]
    end

    params_master, params_workers
end
 
function create_params(cluster::PeerWorkersCluster, user_data_base64)
    params = Dict(
        "InstanceType" => cluster.instance_type,
        "ImageId" => cluster.image_id,
        "KeyName" => cluster.key_name,
        "TagSpecification" => 
            Dict(
                "ResourceType" => "instance",
                "Tag" => [Dict("Key" => "cluster", "Value" => cluster.name),
                          Dict("Key" => "Name", "Value" => "peer") ]
            ),
        "UserData" => user_data_base64,
    )

    if !isnothing(cluster.subnet_id)
        params["SubnetId"] = cluster.subnet_id
    end

    if !isnothing(cluster.placement_group)
        params["Placement"] = Dict("GroupName" => cluster.placement_group)
    end

    if !isnothing(cluster.security_group_id)
        params["SecurityGroupId"] = [cluster.security_group_id]
    end


    params
end

function remove_temp_files(internal_key_name)
    run(`rm /tmp/$internal_key_name`)
    run(`rm /tmp/$internal_key_name.pub`)
end

function try_run(command)

    successfull = false
    while !successfull
        try
            run(command)
            successfull = true
        catch
            @error "failed: $command - trying again"
            sleep(0.5)
        end        
    end

end
 
function set_hostfile(cluster_nodes, internal_key_name)
    # Esperando todo mundo estar pronto.
    @info "---------------- $cluster_nodes"
    for instance in keys(cluster_nodes)
        while get_instance_status(cluster_nodes[instance]) != "running"
            println("Waiting for $instance to be running...")
            sleep(5)
        end
    end

    # Testando se a conexão SSH está ativa.
    for instance in keys(cluster_nodes)
        public_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["ipAddress"]
        connection_ok = false
        while !connection_ok
            try
                connect(public_ip, 22)
                connection_ok = true
            catch e
                println("Waiting for $instance to be accessible...")
                sleep(5)
            end
        end
    end

    # Criando o arquivo hostfile.
    hostfile_content = "127.0.0.1 localhost\n"
    hostfilefile_content = ""
    for instance in keys(cluster_nodes)
        private_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["privateIpAddress"]
        hostfile_content *= "$private_ip $instance\n"
        if instance != :master 
           hostfilefile_content *= "$instance\n"
        end
    end

    #=h = Threads.@spawn begin
        public_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["ipAddress"]
        for instance in keys(cluster_nodes)
            for instance_other in keys(cluster_nodes)
                @info "--- $instance -> $instance_other"
                try_run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "ssh $instance_other uptime"`)
            end
        end
    end=#

    # Atualiza o hostname e o hostfile.
    for instance in keys(cluster_nodes)
        public_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["ipAddress"]
        private_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["privateIpAddress"]
        try_run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "sudo hostnamectl set-hostname $instance"`)
        try_run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "echo '$hostfilefile_content' > /home/ubuntu/hostfile"`)
#        try_run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "awk '{ print \$2 \" \" \$1 }' hostfile >> hosts.tmp"`)
        try_run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "echo '$hostfile_content' >> hosts.tmp"`)
        try_run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "sudo chown ubuntu:ubuntu /etc/hosts"`)
        try_run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "cat hosts.tmp > /etc/hosts"`)
        try_run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "sudo chown root:root /etc/hosts"`)
        try_run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "rm hosts.tmp"`)
    end

    #wait(h)

end


#=
Cria as instâncias. 
=#


function create_instances(cluster::ManagerWorkersCluster)
    cluster_nodes = Dict()

    # Configurando a conexão SSH.
    internal_key_name, user_data = set_up_ssh_connection(cluster.name)

    # Configuração do NFS
    if cluster.shared_fs
        file_system_ip = cluster.environment.file_system_ip
        nfs_user_data = "apt-get -y install nfs-common
mkdir /home/ubuntu/shared/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $file_system_ip:/ /home/ubuntu/shared/
chown -R ubuntu:ubuntu /home/ubuntu/shared
"    
        user_data *= nfs_user_data
    end
    user_data_base64 = base64encode(user_data)

    # Criando as instâncias
    params_master, params_workers = create_params(cluster, user_data_base64)
    # Criar o headnode
    instance_headnode = Ec2.run_instances(1, 1, params_master)
    cluster_nodes[:master] = instance_headnode["instancesSet"]["item"]["instanceId"]

    # Criar os worker nodes.
    params_workers["InstanceType"] = cluster.instance_type_worker
    params_workers["TagSpecification"]["Tag"][2]["Value"] = "worker"
    count = cluster.count
    instances_workers = Ec2.run_instances(count, count, params_workers)
    workers = count
    for i in 1:count
        instance = ""
        if count > 1
            instance = instances_workers["instancesSet"]["item"][i]
        elseif count == 1
            instance = instances_workers["instancesSet"]["item"]
        end
        instance_id = instance["instanceId"]
        cluster_nodes[Symbol("worker$i")] = instance_id
    end

    set_hostfile(cluster_nodes, internal_key_name)

    remove_temp_files(internal_key_name)

    cluster_nodes
end

function create_instances(cluster::PeerWorkersCluster)
    cluster_nodes = Dict()

    # Configurando a conexão SSH.
    internal_key_name, user_data = set_up_ssh_connection(cluster.name)

    # Configuração do NFS
    if cluster.shared_fs
        file_system_ip = cluster.environment.file_system_ip
        nfs_user_data = "apt-get -y install nfs-common
mkdir /home/ubuntu/shared/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $file_system_ip:/ /home/ubuntu/shared/
chown -R ubuntu:ubuntu /home/ubuntu/shared
"    
        user_data *= nfs_user_data
    end
    user_data_base64 = base64encode(user_data)

    # Criando as instâncias
    params = create_params(cluster, user_data_base64)

    # Criar os Peers.
    count = cluster.count
    instances_peers = Ec2.run_instances(count, count, params)
    for i in 1:count
        instance = ""
        if count > 1
            instance = instances_peers["instancesSet"]["item"][i]
        elseif count == 1
            instance = instances_peers["instancesSet"]["item"]
        end
        instance_id = instance["instanceId"]
        cluster_nodes[Symbol("peer$i")] = instance_id
    end

    set_hostfile(cluster_nodes, internal_key_name)

    remove_temp_files(internal_key_name)

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

