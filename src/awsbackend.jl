
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
Estrutura para Armazenar as informações e função de criação do cluster
=#



struct Environment
    subnet_id::String
    placement_group::String
    security_group_id::String
    file_system_id::String  
    file_system_ip::String
end

struct Cluster
    name::String
    environment::Environment
    cluster_nodes::Dict{String, String}
end

function create_environment(cluster_name)
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
    Environment(subnet_id, placement_group, security_group_id, file_system_id, file_system_ip)
end

function create_cluster(cluster_name, instance_type_headnode, instance_type_worker, image_id, key_name, count)
    env = create_environment(cluster_name)
    cluster_nodes = create_instances(cluster_name, instance_type_headnode, instance_type_worker, image_id, key_name, count, env.placement_group, env.security_group_id, env.subnet_id, env.file_system_ip)
    Cluster(cluster_name, env, cluster_nodes)
end

function get_ips(cluster_handle::Cluster)
    ips = Dict()
    for (node, id) in cluster_handle.cluster_nodes
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
    delete_efs(cluster_handle.environment.file_system_id)
    delete_security_group(cluster_handle.environment.security_group_id)
    delete_placement_group(cluster_handle.environment.placement_group)
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

function create_params(instance_type, cluster_name, node_name, image_id, key_name, placement_group, security_group_id, subnet_id, user_data)
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
                          Dict("Key" => "Name", "Value" => node_name) ]
            ),
        "UserData" => user_data
    )
    params
end
 
function remove_temp_files(internal_key_name)
    run(`rm /tmp/$internal_key_name`)
    run(`rm /tmp/$internal_key_name.pub`)
end
 
function set_hostfile(cluster_nodes, internal_key_name)
    # Esperando todo mundo estar pronto.
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
                println("Waiting for $instance to be acessible...")
                sleep(5)
            end
        end
    end

    # Criando o arquivo hostfile.
    hostfile_content = ""
    for instance in keys(cluster_nodes)
        private_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["privateIpAddress"]
        hostfile_content *= "$instance $private_ip\n"
    end

    # Atualiza o hostname e o hostfile.
    for instance in keys(cluster_nodes)
        public_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["ipAddress"]
        private_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["privateIpAddress"]
        run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "sudo hostnamectl set-hostname $instance"`)
        run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "echo '$hostfile_content' > /home/ubuntu/hostfile"`)
        run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "awk '{ print \$2 \" \" \$1 }' hostfile >> hosts.tmp"`)
        run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "sudo chown ubuntu:ubuntu /etc/hosts"`)
        run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "cat hosts.tmp >> /etc/hosts"`)
        run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "sudo chown root:root /etc/hosts"`)
        run(`ssh -i /tmp/$internal_key_name -o StrictHostKeyChecking=no ubuntu@$public_ip "rm hosts.tmp"`)
    end
end

#=
Versão MasterWorker com sistema de arquivo compartilhado.
Precisa usar no mínimo c6i.large.
=#

function create_instances(cluster_name, instance_type_headnode, instance_type_worker, image_id, key_name, count, placement_group, security_group_id, subnet_id, file_system_ip)
    cluster_nodes = Dict()

    # Configurando a conexão SSH.
    internal_key_name, user_data = set_up_ssh_connection(cluster_name)
      
    # Configuração do NFS
    nfs_user_data = "apt-get -y install nfs-common
mkdir /home/ubuntu/shared/
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $file_system_ip:/ /home/ubuntu/shared/
chown -R ubuntu:ubuntu /home/ubuntu/shared
"
     # Criando o headnode
     params = create_params(instance_type_headnode, cluster_name, "headnode", image_id, key_name, placement_group, security_group_id, subnet_id, user_data_base64)
     instance_headnode = Ec2.run_instances(1,1,params)
     cluster_nodes["headnode"] = instance_headnode["instancesSet"]["item"]["instanceId"]
 
     # Criando os worker nodes.
     params = create_params(instance_type_worker, cluster_name, "worker", image_id, key_name, placement_group, security_group_id, subnet_id, user_data_base64)
     instances_workers = Ec2.run_instances(count,count,params)
     for i in 1:count
         instance = ""
         if count > 1
             instance = instances_workers["instancesSet"]["item"][i]
         elseif count == 1
             instance = instances_workers["instancesSet"]["item"]
         end
         instance_id = instance["instanceId"]
         cluster_nodes["worker$i"] = instance_id
     end
 
     set_hostfile(cluster_nodes, internal_key_name)
    
     remove_temp_files(internal_key_name)
     cluster_nodes
end

#=
Versão MasterWorker sem sistema de arquivos compartilhado.
=#
function create_instances(cluster_name, instance_type_headnode, instance_type_worker, image_id, key_name, count, placement_group, security_group_id, subnet_id)
    # Dicionário com o nome e id das instâncias.
    cluster_nodes = Dict()
    
    # Configurando a conexão SSH.
    internal_key_name, user_data = set_up_ssh_connection(cluster_name)
    user_data_base64 = base64encode(user_data)

    # Criando o headnode
    params = create_params(instance_type_headnode, cluster_name, "headnode", image_id, key_name, placement_group, security_group_id, subnet_id, user_data_base64)
    instance_headnode = Ec2.run_instances(1,1,params)
    cluster_nodes["headnode"] = instance_headnode["instancesSet"]["item"]["instanceId"]

    # Criando os worker nodes.
    params = create_params(instance_type_worker, cluster_name, "worker", image_id, key_name, placement_group, security_group_id, subnet_id, user_data_base64)
    instances_workers = Ec2.run_instances(count,count,params)
    for i in 1:count
        instance = ""
        if count > 1
            instance = instances_workers["instancesSet"]["item"][i]
        elseif count == 1
            instance = instances_workers["instancesSet"]["item"]
        end
        instance_id = instance["instanceId"]
        cluster_nodes["worker$i"] = instance_id
    end

    set_hostfile(cluster_nodes, internal_key_name)
   
    remove_temp_files(internal_key_name)
    cluster_nodes
end

#=
Versão Peers sem sistema de arquivos compartilhado.
=#
function create_instances(cluster_name, instance_type_peer, image_id, key_name, count, placement_group, security_group_id, subnet_id)
    # Dicionário com o nome e id das instâncias.
    cluster_nodes = Dict()
    
    # Configurando a conexão SSH.
    internal_key_name, user_data = set_up_ssh_connection(cluster_name)
    user_data_base64 = base64encode(user_data)

    # Criando os Peers.
    params = create_params(instance_type_peer, cluster_name, "peer", image_id, key_name, placement_group, security_group_id, subnet_id, user_data_base64)
    instances_peers = Ec2.run_instances(count,count,params)
    for i in 1:count
        instance = ""
        if count > 1
            instance = instances_peers["instancesSet"]["item"][i]
        elseif count == 1
            instance = instances_peers["instancesSet"]["item"]
        end
        instance_id = instance["instanceId"]
        cluster_nodes["peer$i"] = instance_id
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

