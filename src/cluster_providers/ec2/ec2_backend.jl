
#=
For this module to work, you`ll need AWS credentials in the ${HOME}/.aws directory. 
=# 

using Random
using AWS: @service
using Serialization
using Base64
using Sockets
@service Ec2 
@service Efs

#=
Estrutura para Armazenar as informações e função de criação do cluster
=#

mutable struct SharedFSInfo 
    file_system_id::String  
    file_system_ip::String
end

mutable struct EC2ManagerWorkers <: ManagerWorkers #Cluster
    name::String
    instance_type_manager::String
    instance_type_worker::String
    count::Int
    image_id_manager::String
    image_id_worker::String
    user_manager::String
    user_worker::String
    subnet_id::Union{String, Nothing}
    placement_group::Union{String, Nothing}
    auto_pg::Bool
    security_group_id::Union{String, Nothing}
    auto_sg::Bool
    environment::Union{SharedFSInfo, Nothing}
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    shared_fs::Bool
    features::Dict{Symbol, Any}
end


mutable struct EC2PeerWorkers <: PeerWorkers # Cluster
    name::String
    instance_type::String
    count::Int
    image_id::String
    user::String
    subnet_id::Union{String, Nothing}
    placement_group::Union{String, Nothing}
    auto_pg::Bool
    security_group_id::Union{String, Nothing}
    auto_sg::Bool
    environment::Union{SharedFSInfo, Nothing}
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    shared_fs::Bool
    features::Dict{Symbol, Any}
end

mutable struct EC2PeerWorkersMPI <: PeerWorkersMPI # Cluster
    name::String
    instance_type::String
    count::Int
    image_id::String
    user::String
    subnet_id::Union{String, Nothing}
    placement_group::Union{String, Nothing}
    auto_pg::Bool
    security_group_id::Union{String, Nothing}
    auto_sg::Bool
    environment::Union{SharedFSInfo, Nothing}
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    shared_fs::Bool
    features::Dict{Symbol, Any}
end

# PUBLIC
function ec2_create_cluster(cluster::Cluster)
 
    if cluster.shared_fs
        file_system_id = ec2_create_efs(cluster.subnet_id, cluster.security_group_id)
        println("File System ID: $file_system_id")
        file_system_ip = ec2_get_mount_target_ip(file_system_id)
        println("File System IP: $file_system_ip")
        cluster.environment = SharedFSInfo(file_system_id, file_system_ip)
    end

    cluster.cluster_nodes = ec2_create_instances(cluster)
    cluster
end


function ec2_get_ips_instance(instance_id::String)
    public_ip = Ec2.describe_instances(Dict("InstanceId" => instance_id))["reservationSet"]["item"]["instancesSet"]["item"]["ipAddress"]
    private_ip = Ec2.describe_instances(Dict("InstanceId" => instance_id))["reservationSet"]["item"]["instancesSet"]["item"]["privateIpAddress"]
    Dict(:public_ip => public_ip, :private_ip => private_ip)
end

# PUBLIC
function ec2_terminate_cluster(cluster::Cluster)
    ec2_delete_instances(cluster.cluster_nodes) 
    ec2_await_status(cluster.cluster_nodes, "terminated")
    cluster.shared_fs && ec2_delete_efs(cluster.file_system_id)
    cluster.auto_sg && ec2_delete_security_group(cluster.security_group_id)
    cluster.auto_pg && ec2_delete_placement_group(cluster.placement_group)
end


#=
Grupo de Alocação
=#
# PUBLIC
function ec2_create_placement_group(name)
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

function ec2_delete_placement_group(name)
    params = Dict("GroupName" => name)
    delete_placement_group(name)
end

#=
Grupo de Segurança 
=#
# PUBLIC
function ec2_create_security_group(name, description)
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

function ec2_delete_security_group(id)
    Ec2.delete_security_group(Dict("GroupId" => id))
end

#=
Criação de Instâncias
=# 

# Funções auxiliares.
# Funções auxiliares.
function ec2_set_up_ssh_connection(cluster_name, comment)   

    internal_key_name = cluster_name
 
    ssh_path = joinpath(homedir(), ".ssh")
 
    !isdir(ssh_path) && mkdir(ssh_path)
 
    keypath = joinpath(ssh_path, "$internal_key_name.key")
    pubpath = joinpath(ssh_path, "$internal_key_name.key.pub")
 
    # Criar chave interna pública e privada do SSH.
    # chars = ['a':'z'; 'A':'Z'; '0':'9']
    # random_suffix = join(chars[Random.rand(1:length(chars), 5)])
    run(`ssh-keygen -t rsa -b 2048 -f $keypath -C $comment -N ""`)
    run(`chmod 400 $keypath`)
    private_key = base64encode(read(keypath, String))
    public_key = base64encode(read(pubpath, String))
 
    private_key, public_key
 end

 function ec2_get_user_data(cluster_name, user, private_key, public_key)

    # Define o script que irá instalar a chave pública e privada no headnode e workers.
    user_data = "#!/bin/bash
    echo $private_key | base64 -d > /home/$user/.ssh/$cluster_name
    echo $public_key | base64 -d > /home/$user/.ssh/$cluster_name.pub
    echo 'Host *
       IdentityFile /home/$user/.ssh/$cluster_name
       StrictHostKeyChecking no' > /home/$user/.ssh/config
    cat /home/$user/.ssh/$cluster_name.pub >> /home/$user/.ssh/authorized_keys
    chown -R $user:$user /home/$user/.ssh
    chmod 600 /home/$user/.ssh/*
    sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 1000/g' /etc/ssh/sshd_config
    sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 100/g' /etc/ssh/sshd_config
    systemctl restart ssh
    "

    return user_data
 end

#=
function ec2_set_up_ssh_connection(cluster_name)  

    internal_key_name = cluster_name

    ssh_path = joinpath(homedir(), ".ssh")

    !isdir(ssh_path) && mkdir(ssh_path)

    keypath = joinpath(ssh_path, "$internal_key_name.key")
    pubpath = joinpath(ssh_path, "$internal_key_name.key.pub")
                      
   # Criar chave interna pública e privada do SSH.
   # chars = ['a':'z'; 'A':'Z'; '0':'9']
   # random_suffix = join(chars[Random.rand(1:length(chars), 5)])
   run(`ssh-keygen -f $keypath -N ""`)
   private_key = base64encode(read(keypath, String))
   public_key = base64encode(read(pubpath, String))
  
   # Define o script que irá instalar a chave pública e privada no headnode e workers.
   user_data = "#!/bin/bash
echo $private_key | base64 -d > /home/ubuntu/.ssh/$cluster_name
echo $public_key | base64 -d > /home/ubuntu/.ssh/$cluster_name.pub
echo 'Host *
   IdentityFile /home/ubuntu/.ssh/$cluster_name
   StrictHostKeyChecking no' > /home/ubuntu/.ssh/config
cat /home/ubuntu/.ssh/$cluster_name.pub >> /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/*
sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 1000/g' /etc/ssh/sshd_config
sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 100/g' /etc/ssh/sshd_config
systemctl restart ssh
"
   [internal_key_name, user_data]
end
=#

function ec2_create_params(cluster::ManagerWorkers, user_data_base64)

   user_data_manager_base64, user_data_worker_base64 = user_data_base64

   params_manager = Dict(
        "InstanceType" => cluster.instance_type_manager,
        "ImageId" => cluster.image_id_manager,
        "TagSpecification" => 
            Dict(
                "ResourceType" => "instance",
                "Tag" => [Dict("Key" => "cluster", "Value" => cluster.name),
                          Dict("Key" => "Name", "Value" => "manager") ]
            ),
        "UserData" => user_data_manager_base64,
    )

    params_workers = Dict(
        "InstanceType" => cluster.instance_type_worker,
        "ImageId" => cluster.image_id_worker,
        "TagSpecification" => 
            Dict(
                "ResourceType" => "instance",
                "Tag" => [Dict("Key" => "cluster", "Value" => cluster.name),
                          Dict("Key" => "Name", "Value" => "worker") ]
            ),
        "UserData" => user_data_worker_base64,
    )

    if !isnothing(cluster.subnet_id)
        params_manager["SubnetId"] = cluster.subnet_id
        params_workers["SubnetId"] = cluster.subnet_id
    end

    if !isnothing(cluster.placement_group)
        params_manager["Placement"] = Dict("GroupName" => cluster.placement_group)
        params_workers["Placement"] = Dict("GroupName" => cluster.placement_group)
    end

    if !isnothing(cluster.security_group_id)
        params_manager["SecurityGroupId"] = [cluster.security_group_id]
        params_workers["SecurityGroupId"] = [cluster.security_group_id]
    end

    params_manager, params_workers
end
 
function ec2_create_params(cluster::PeerWorkers, user_data_base64)
    params = Dict(
        "InstanceType" => cluster.instance_type,
        "ImageId" => cluster.image_id,
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

function ec2_remove_temp_files(internal_key_name)
    ssh_path = joinpath(homedir(), ".ssh")
    keypath = joinpath(ssh_path, "$internal_key_name.key")
    pubpath = joinpath(ssh_path, "$internal_key_name.key.pub")
    rm(keypath)
    rm(pubpath)
end

function ec2_set_hostfile(cluster_nodes, internal_key_name, user)
    ec2_set_hostfile(cluster_nodes, internal_key_name, user, user)
end
 
function ec2_set_hostfile(cluster_nodes, internal_key_name, user_manager, user_worker)
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
            end
        end
    end

    # Criando o arquivo hostfile.
    hostfile_content = "127.0.0.1 localhost\n"
    hostfilefile_content = ""
    for instance in keys(cluster_nodes)
        private_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["privateIpAddress"]
        hostfile_content *= "$private_ip $instance\n"
        if instance != :manager 
           hostfilefile_content *= "$instance\n"
        end
    end

    ssh_path = joinpath(homedir(), ".ssh")
    keypath = joinpath(ssh_path, "$internal_key_name.key")

    # Atualiza o hostname e o hostfile.
    for instance in keys(cluster_nodes)
        user = instance == :manager ? user_manager : user_worker
        public_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["ipAddress"]
       # private_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["privateIpAddress"]
        try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user@$public_ip "sudo hostnamectl set-hostname $instance"`)
        try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user@$public_ip "echo '$hostfilefile_content' > /home/$user/hostfile"`)
#        try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user@$public_ip "awk '{ print \$2 \" \" \$1 }' hostfile >> hosts.tmp"`)
        try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user@$public_ip "echo '$hostfile_content' >> hosts.tmp"`)
        try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user@$public_ip "sudo chown $user:$user /etc/hosts"`)
        try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user@$public_ip "cat hosts.tmp > /etc/hosts"`)
        try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user@$public_ip "sudo chown root:root /etc/hosts"`)
        try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user@$public_ip "rm hosts.tmp"`)
    end

    #wait(h)

end


#=
Cria as instâncias. 
=#


function ec2_create_instances(cluster::ManagerWorkers)
    cluster_nodes = Dict()

    # Configurando a conexão SSH.

    private_key, public_key = ec2_set_up_ssh_connection(cluster.name, cluster.user_manager)

    user_data_manager = ec2_get_user_data(cluster.name, cluster.user_manager, private_key, public_key)
    user_data_worker = ec2_get_user_data(cluster.name, cluster.user_worker, private_key, public_key)

    internal_key_name = cluster.name

    # Configuração do NFS
    if cluster.shared_fs
        file_system_ip = cluster.environment.file_system_ip
        nfs_user_data_manager = "apt-get -y install nfs-common
mkdir /home/$user_manager/shared/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $file_system_ip:/ /home/$user_manager/shared/
chown -R $user_manager:$user_manager /home/$user_manager/shared
"    
        nfs_user_data_worker = "apt-get -y install nfs-common
mkdir /home/$user_worker/shared/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $file_system_ip:/ /home/$user_worker/shared/
chown -R $user_worker:$user_worker /home/$user_worker/shared
"    
        user_data_manager *= nfs_user_data_manager
        user_data_worker *= nfs_user_data_worker
    end

    user_data_manager_base64 = base64encode(user_data_manager)
    user_data_worker_base64 = base64encode(user_data_worker)

    # Criando as instâncias
    params_manager, params_workers = ec2_create_params(cluster, (user_data_manager_base64, user_data_worker_base64))

    # Criar o headnode
    instance_headnode = run_instances(1, 1, params_manager)
    cluster_nodes[:manager] = instance_headnode["instancesSet"]["item"]["instanceId"]

    # Criar os worker nodes.
    params_workers["InstanceType"] = cluster.instance_type_worker
    params_workers["TagSpecification"]["Tag"][2]["Value"] = "worker"
    count = cluster.count
    instances_workers = run_instances(count, count, params_workers)
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

    ec2_await_status(cluster_nodes, "running")
    ec2_await_check(cluster_nodes, "ok")

    ec2_set_hostfile(cluster_nodes, internal_key_name, cluster.user_manager, cluster.user_worker)

    #ec2_remove_temp_files(internal_key_name)

    cluster_nodes
end

function ec2_create_instances(cluster::PeerWorkers)
    cluster_nodes = Dict()

    # Configurando a conexão SSH.
    private_key, public_key = ec2_set_up_ssh_connection(cluster.name, cluster.user)
    user_data = ec2_get_user_data(cluster.name, cluster.user, private_key, public_key)

    internal_key_name = cluster.name

    # Configuração do NFS
    if cluster.shared_fs
        file_system_ip = cluster.environment.file_system_ip
        nfs_user_data = "apt-get -y install nfs-common
mkdir /home/$user/shared/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $file_system_ip:/ /home/$user/shared/
chown -R $user:$user /home/$user/shared
"    
        user_data *= nfs_user_data
    end
    user_data_base64 = base64encode(user_data)

    # Criando as instâncias
    params = ec2_create_params(cluster, user_data_base64)

    # Criar os Peers.
    count = cluster.count
    instances_peers = run_instances(count, count, params)
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

    ec2_await_status(cluster_nodes, "running")
    ec2_await_check(cluster_nodes, "ok")

    ec2_set_hostfile(cluster_nodes, internal_key_name, cluster.user)

   # ec2_remove_temp_files(internal_key_name)

    cluster_nodes
end

function ec2_await_status(cluster_nodes, status)
    for nodeid in keys(cluster_nodes)
        print("Waiting for $nodeid to be $status ...")
        while ec2_get_instance_status(cluster_nodes[nodeid]) != status
            print(".")
            sleep(2)
        end
        println("successfull")
    end
end

function ec2_await_check(cluster_nodes, status)
    for nodeid in keys(cluster_nodes)
        print("Waiting for $nodeid to be $status ...")
        while ec2_get_instance_check(cluster_nodes[nodeid]) != status
            print(".")
            sleep(2)
        end
        println("successfull")
    end
end

# PUBLIC
function ec2_cluster_status(cluster::Cluster, status_list)
    cluster_nodes = cluster.cluster_nodes
    for nodeid in keys(cluster_nodes)
        !(ec2_get_instance_status(cluster_nodes[nodeid]) in status_list) && return false
    end
    return true
end

function ec2_cluster_ready(cluster::Cluster; status="ok")
    cluster_nodes = cluster.cluster_nodes
    for nodeid in keys(cluster_nodes)
        ec2_get_instance_check(cluster_nodes[nodeid]) != status && return false
    end
    return true
end

function ec2_delete_instances(cluster_nodes)
    for id in values(cluster_nodes)
        Ec2.terminate_instances(id)
    end
end

function ec2_get_instance_status(id)
    try
        description = Ec2.describe_instances(Dict("InstanceId" => id))    
        if haskey(description["reservationSet"], "item")
            description["reservationSet"]["item"]["instancesSet"]["item"]["instanceState"]["name"]
        else
            "notfound"
        end
    catch _
        "notfound"
    end
end

function ec2_get_instance_check(id)
    try
        description = Ec2.describe_instance_status(Dict("InstanceId" => id))
        if haskey(description["instanceStatusSet"], "item")
            description["instanceStatusSet"]["item"]["instanceStatus"]["status"]
        else
            "notfound"
        end
    catch _
        "notfound"
    end
end

function ec2_get_instance_subnet(id)
    description = Ec2.describe_instances(Dict("InstanceId" => id))
    description["reservationSet"]["item"]["instancesSet"]["item"]["subnetId"]
end

#=
Sistema de Arquivo Compartilhado
=#

function ec2_create_efs(subnet_id, security_group_id)
    chars = ['a':'z'; 'A':'Z'; '0':'9']
    creation_token = join(chars[Random.rand(1:length(chars), 64)])
    file_system_id = Efs.create_file_system(creation_token)["FileSystemId"]
    ec2_create_mount_point(file_system_id, subnet_id, security_group_id)
    file_system_id
end

function ec2_create_mount_point(file_system_id, subnet_id, security_group_id)
    params = Dict(
        "SecurityGroups" => [security_group_id]
    )

    status = Efs.describe_file_systems(Dict("FileSystemId" => file_system_id))["FileSystems"][1]["LifeCycleState"]
    while status != "available"
        println("Waiting for File System to be available...")
        sleep(2)
        status = Efs.describe_file_systems(Dict("FileSystemId" => file_system_id))["FileSystems"][1]["LifeCycleState"]
    end
    println("Creating Mount Target...")

    mount_target_id = Efs.create_mount_target(file_system_id, subnet_id, params)["MountTargetId"]
    status = Efs.describe_mount_targets(Dict("MountTargetId" => mount_target_id))["MountTargets"][1]["LifeCycleState"]
    while status != "available"
        println("Waiting for mount target to be available...")
        sleep(2)
        status = Efs.describe_mount_targets(Dict("MountTargetId" => mount_target_id))["MountTargets"][1]["LifeCycleState"]
    end
    mount_target_id
end

function ec2_get_mount_target_ip(file_system_id)
    mount_target_id = Efs.describe_mount_targets(Dict("FileSystemId" => file_system_id))["MountTargets"][1]["MountTargetId"]
    ip = Efs.describe_mount_targets(Dict("MountTargetId" => mount_target_id))["MountTargets"][1]["IpAddress"]
    ip
end

function ec2_delete_efs(file_system_id)
    for mount_target in Efs.describe_mount_targets(Dict("FileSystemId" => file_system_id))["MountTargets"]
        Efs.delete_mount_target(mount_target["MountTargetId"])
    end
    while length(Efs.describe_mount_targets(Dict("FileSystemId" => file_system_id))["MountTargets"]) != 0
        println("Waiting for mount targets to be deleted...")
        sleep(2)
    end
    Efs.delete_file_system(file_system_id)
end

# Heron: "se as definições são a mesma para os tipos de clusters, use cluster::Cluster como parâmetro em um único método"

# PUBLIC
ec2_can_interrupt(cluster::Cluster) = ec2_cluster_isrunning(cluster)

# Interrupt cluster instances. If someone is not in "running" state, raise an exception.
# PUBLIC
function ec2_interrupt_cluster(cluster::Cluster)
    ec2_stop_instances(cluster)
    ec2_await_status(cluster.cluster_nodes, "stopped")
end

# PUBLIC
ec2_can_resume(cluster::Cluster) = ec2_cluster_status(cluster, ["stopped"])

# Start interrupted cluster instances or reboot running cluster instances.
# All instances must be in "interrupted" or "running" state.
# If some instance is not in "interrupted" or "running" state, raise an exception.
# PUBLIC

function ec2_resume_cluster(cluster::PeerWorkers)
    ec2_resume_cluster(cluster, cluster.user, cluster.user)
end

function ec2_resume_cluster(cluster::ManagerWorkers)
    ec2_resume_cluster(cluster, cluster.user_manager, cluster.user_worker)
end

function ec2_resume_cluster(cluster::Cluster, user_manager, user_worker)
    home = ENV["HOME"]
    ssh_path = joinpath(homedir(), ".ssh")
    keypath = joinpath(ssh_path, "$(cluster.name).key")

    ec2_start_instances(cluster)
    ec2_await_status(cluster.cluster_nodes, "running")
    ec2_await_check(cluster.cluster_nodes, "ok")
    for instance in keys(cluster.cluster_nodes)
        user = instance == :manager ? user_manager : user_worker
        public_ip = Ec2.describe_instances(Dict("InstanceId" => cluster.cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["ipAddress"]
        run(`ssh-keygen -f $home/.ssh/known_hosts -R $public_ip`)
        try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user@$public_ip uptime`)
    end
end


# Check if the cluster instances are running or interrupted.
ec2_cluster_isrunning(cluster::Cluster) = ec2_cluster_status(cluster, ["running"]) && ec2_cluster_ready(cluster) 
ec2_cluster_isstopped(cluster::Cluster) = ec2_cluster_status(cluster, ["stopped"])

function ec2_stop_instances(cluster::Cluster)
    for id in values(cluster.cluster_nodes)
        Ec2.stop_instances(id)
    end
end

function ec2_start_instances(cluster::Cluster)
    for id in values(cluster.cluster_nodes)
        Ec2.start_instances(id)
    end
end

# PUBLIC
function ec2_get_ips(cluster::Cluster)
    ips = Dict()
    for (node, id) in cluster.cluster_nodes
         ips[node] = ec2_get_ips_instance(id) 
    end
    ips
end



function delete_placement_group(
    groupName; aws_config::AbstractAWSConfig=global_aws_config()
)
    return Ec2.ec2(
        "DeletePlacementGroup",
        Dict{String,Any}("GroupName" => groupName);
        aws_config=aws_config,
        feature_set=Ec2.SERVICE_FEATURE_SET,
    )
end
function delete_placement_group(
    groupName,
    params::AbstractDict{String};
    aws_config::AbstractAWSConfig=global_aws_config(),
)
    return Ec2.ec2(
        "DeletePlacementGroup",
        Dict{String,Any}(
            mergewith(_merge, Dict{String,Any}("GroupName" => groupName), params)
        );
        aws_config=aws_config,
        feature_set= Ec2.SERVICE_FEATURE_SET,
    )
end

function run_instances(
    MaxCount, MinCount; aws_config::AbstractAWSConfig=global_aws_config()
)
    return Ec2.ec2(
        "RunInstances",
        Dict{String,Any}(
            "MaxCount" => MaxCount, "MinCount" => MinCount, "ClientToken" => string(Ec2.uuid4())
        );
        aws_config=aws_config,
        feature_set=Ec2.SERVICE_FEATURE_SET,
    )
end
function run_instances(
    MaxCount,
    MinCount,
    params::AbstractDict{String};
    aws_config::AbstractAWSConfig=global_aws_config(),
)
    return Ec2.ec2(
        "RunInstances",
        Dict{String,Any}(
            mergewith(
                _merge,
                Dict{String,Any}(
                    "MaxCount" => MaxCount,
                    "MinCount" => MinCount,
                    "ClientToken" => string(Ec2.uuid4()),
                ),
                params,
            ),
        );
        aws_config=aws_config,
        feature_set=Ec2.SERVICE_FEATURE_SET,
    )
end

