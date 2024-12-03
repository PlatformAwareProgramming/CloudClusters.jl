using Random
using AWS: @service
using Serialization
using Base64
using Sockets

using JSON

import GoogleCloud as GCPAPI

# Creates a GCP session and stores it.
gcp_session = GCPAPI.GoogleSession(joinpath(ENV["HOME"], ".gcp", "credentials.json"), ["cloud-platform"])
GCPAPI.set_session!(GCPAPI.compute, gcp_session)


#=
Estrutura para Armazenar as informações e função de criação do cluster
=#

mutable struct GCPManagerWorkers <: ManagerWorkers #Cluster
    name::String
    source_image_master::String
    source_image_worker::String
    count::Int
#=     instance_type_master::String
    instance_type_worker::String
    count::Int
    image_id_master::String
    image_id_worker::String
    subnet_id::Union{String, Nothing}
    placement_group::Union{String, Nothing}
    auto_pg::Bool
    security_group_id::Union{String, Nothing}
    auto_sg::Bool
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    shared_fs::Bool
    features::Dict{Symbol, Any} =#
end


mutable struct GCPPeerWorkers <: PeerWorkers # Cluster
    name::String
    source_image::String
    count::Int
    instance_type::String
    zone::String
    project::String
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
#=     instance_type::String
    count::Int
    image_id::String
    subnet_id::Union{String, Nothing}
    placement_group::Union{String, Nothing}
    auto_pg::Bool
    security_group_id::Union{String,Nothing}
    auto_sg::Bool
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    shared_fs::Bool
    features::Dict{Symbol, Any} =#
end

mutable struct GCPPeerWorkersMPI <: PeerWorkersMPI # Cluster
    name::String
    #source_image::String
    #count::Int
#=     instance_type::String
    count::Int
    image_id::String
    subnet_id::Union{String, Nothing}
    placement_group::Union{String, Nothing}
    auto_pg::Bool
    security_group_id::Union{String,Nothing}
    auto_sg::Bool
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    shared_fs::Bool
    features::Dict{Symbol, Any} =#
end

# PUBLIC
"""
Creates a compute instances cluster and returns it.

-> Cluster
"""
function gcp_create_cluster(cluster::Cluster)
    return gcp_create_instances(cluster)
end


"""
-> Dict
"""
function gcp_get_ips_instance(cluster::Cluster, name)
    public_ip = gcp_get_instance_dict(cluster, name)["networkInterfaces"][1]["accessConfigs"][1]["natIP"]
    private_ip = gcp_get_instance_dict(cluster, name)["networkInterfaces"][1]["networkIP"]
    
    return Dict(:public_ip => public_ip, :private_ip => private_ip)
end

# PUBLIC
function gcp_terminate_cluster(cluster::Cluster)
    gcp_delete_instances(cluster) 
    for instance in cluster.cluster_nodes
        status = gcp_get_instance_status(cluster, instance[2])
        while status != "terminated"
            println("Waiting for instances to terminate...")
            sleep(5)
            status = gcp_get_instance_status(cluster, instance[2])
        end
    end
    
    cluster.shared_fs && gcp_delete_efs(cluster.file_system_id)
    cluster.auto_sg && gcp_delete_security_group(cluster.security_group_id)
    cluster.auto_pg && gcp_delete_placement_group(cluster.placement_group)

    return
end


#=
Grupo de Alocação
=#
# PUBLIC
function gcp_create_placement_group(name)
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
    
    return Ec2.create_placement_group(params)["placementGroup"]["groupName"]
end

function gcp_delete_placement_group(name)
    params = Dict("GroupName" => name)
    Ec2.delete_placement_group(name)
end

#=
Grupo de Segurança 
=#
# PUBLIC
function gcp_create_security_group(name, description)
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
    return id
end

function gcp_delete_security_group(id)
    Ec2.delete_security_group(Dict("GroupId" => id))
end

#=
Criação de Instâncias
=# 

# Funções auxiliares.
function gcp_set_up_ssh_connection(cluster_name)                    
   # Criar chave interna pública e privada do SSH.
   # chars = ['a':'z'; 'A':'Z'; '0':'9']
   # random_suffix = join(chars[Random.rand(1:length(chars), 5)])
   internal_key_name = cluster_name
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
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/*
sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 1000/g' /etc/ssh/sshd_config
sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 100/g' /etc/ssh/sshd_config
systemctl restart ssh
"
   return [internal_key_name, user_data]
end

function gcp_create_params(cluster::ManagerWorkers, user_data_base64)
   params_master = Dict(
        "InstanceType" => cluster.instance_type_master,
        "ImageId" => cluster.image_id_master,
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

    return params_master, params_workers
end
 
function gcp_create_params(cluster::PeerWorkers, user_data_base64)
#=     params = Dict(
        "InstanceType" => cluster.instance_type,
        "ImageId" => cluster.source_image,
        "TagSpecification" => 
            Dict(
                "ResourceType" => "instance",
                "Tag" => [Dict("Key" => "cluster", "Value" => cluster.name),
                          Dict("Key" => "Name", "Value" => "peer") ]
            ),
        "UserData" => user_data_base64,
    ) =#

    params = Vector{Dict}()
    
    for i = 1:cluster.count
        push!(params, Dict(
            "disks" => [Dict(
                "autoDelete" => true,
                "boot" => true,
                "initializeParams" => Dict(
                    "diskSizeGb" => 50,
                    "sourceImage" => "projects/$(cluster.source_image)"
                ),
                "mode" => "READ_WRITE",
                "type" => "PERSISTENT"
            )],
            "zone" => cluster.zone,
            "machineType" => "zones/$(cluster.zone)/machineTypes/$(cluster.instance_type)",
            "name" => lowercase(cluster.name) * string(i),
            "networkInterfaces" => [Dict(
                "accessConfigs" => [Dict(
                    "name" => "external-nat",
                    "type" => "ONE_TO_ONE_NAT"
                )],
                "network" => "https://www.googleapis.com/compute/v1/projects/cloudclusters/global/networks/default"
            )],
            "metadata" => 
                "items" => Dict( # add ssh-keys here
                    "key" => "startup-script",
                    "value" => user_data_base64
            )
        ))
    end

#=     if !isnothing(cluster.zone)
        params["zone"] = cluster.zone
    end =#

#=     if !isnothing(cluster.placement_group)
        params["Placement"] = Dict("GroupName" => cluster.placement_group)
    end =#

#=     if !isnothing(cluster.security_group_id)
        params["SecurityGroupId"] = [cluster.security_group_id]
    end =#

    return params
end

function gcp_remove_temp_files(internal_key_name)
    run(`rm /tmp/$internal_key_name`)
    run(`rm /tmp/$internal_key_name.pub`)
end


 
function gcp_set_hostfile(cluster::Cluster, internal_key_name)
    # Testando se a conexão SSH está ativa.
    for i = 1:cluster.count
        instance = lowercase(cluster.name) * string(i)
        public_ip = gcp_get_ips_instance(cluster, instance)[:public_ip]
        connection_ok = false
        while !connection_ok
            try
                connect(public_ip, 22)
                connection_ok = true
            catch e
                println("Waiting for peer$i to be accessible...")
            end
        end
    end

    # Criando o arquivo hostfile.
    hostfile_content = "127.0.0.1 localhost\n"
    hostfilefile_content = ""
    for i = 1:cluster.count
        instance = lowercase(cluster.name) * string(i)
        private_ip = gcp_get_ips_instance(cluster, instance)[:private_ip]
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
    for i = 1:cluster.count
        instance = lowercase(cluster.name) * string(i)
        public_ip = gcp_get_ips_instance(cluster, instance)[:public_ip]
       # private_ip = Ec2.describe_instances(Dict("InstanceId" => cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["privateIpAddress"]
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


function gcp_create_instances(cluster::ManagerWorkers)
    new_cluster = cluster
    cluster_nodes = Dict()

    # Configurando a conexão SSH.
    internal_key_name, user_data = gcp_set_up_ssh_connection(cluster.name)

    user_data_base64 = base64encode(user_data)

    # Criando as instâncias
    params_master, params_workers = gcp_create_params(cluster, user_data_base64)
    # Criar o headnode
    instance_headnode = Ec2.run_instances(1, 1, params_master)
    cluster_nodes[:master] = instance_headnode["instancesSet"]["item"]["instanceId"]

    # Criar os worker nodes.
    params_workers["InstanceType"] = new_cluster.instance_type_worker
    params_workers["TagSpecification"]["Tag"][2]["Value"] = "worker"
    count = new_cluster.count
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

    new_cluster.cluster_nodes = cluster_nodes

    gcp_await_status(new_cluster, cluster_nodes, "RUNNING")

    gcp_set_hostfile(new_cluster, internal_key_name)

    gcp_remove_temp_files(internal_key_name)

    return new_cluster
end

function gcp_create_instances(cluster::PeerWorkers)
    new_cluster = cluster
    cluster_nodes = Dict()

    # Configurando a conexão SSH.
    internal_key_name, user_data = gcp_set_up_ssh_connection(new_cluster.name)

    user_data_base64 = base64encode(user_data)

    # Criando as instâncias
    params = gcp_create_params(new_cluster, user_data_base64)

    # Criar os Peers.
    gcp_compute_instance_insert(new_cluster, params)

    for i = 1:new_cluster.count
        cluster_nodes[Symbol("peer$i")] = lowercase(new_cluster.name) * string(i)
    end

    new_cluster.cluster_nodes = cluster_nodes

    gcp_await_status(new_cluster, cluster_nodes, "RUNNING")

    gcp_set_hostfile(new_cluster, internal_key_name)

   # gcp_remove_temp_files(internal_key_name)

    return new_cluster
end

function gcp_compute_instance_insert(cluster::Cluster, params)
    for i = 1:cluster.count
        GCPAPI.compute(:Instance, :insert, cluster.project, cluster.zone; data=params[i])
    end
end

function gcp_await_status(cluster::Cluster, cluster_nodes, status)
    for nodeid in keys(cluster_nodes)
        print("Waiting for $nodeid to be $status ...")
        while gcp_get_instance_status(cluster, cluster_nodes[nodeid]) != status
            print(".")
            sleep(5)
        end
        println("successfull")
    end
end

# PUBLIC
function gcp_cluster_status(cluster::Cluster, status_list)
    cluster_nodes = cluster.cluster_nodes
    for nodeid in keys(cluster_nodes)
        !(gcp_get_instance_status(cluster, cluster_nodes[nodeid]) in status_list) && return false
    end
    return true
end

function gcp_cluster_ready(cluster::Cluster; status="ok")
    cluster_nodes = cluster.cluster_nodes
    for nodeid in keys(cluster_nodes)
        gcp_get_instance_check(cluster_nodes[nodeid]) != status && return false
    end
    return true
end

function gcp_delete_instances(cluster::Cluster)
    for id in values(cluster.cluster_nodes)
        GCPAPI.compute(:Instance, :delete, cluster.project, cluster.zone, id)
    end
end

function gcp_get_instance_status(cluster::Cluster, id)
    try
        return gcp_get_instance_dict(cluster, id)["status"]
    catch _
        return "notfound"
    end
end

function gcp_get_instance_check(id)
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

function gcp_get_instance_subnet(id)
    description = Ec2.describe_instances(Dict("InstanceId" => id))
    description["reservationSet"]["item"]["instancesSet"]["item"]["subnetId"]
end

# PUBLIC
gcp_can_interrupt(cluster::Cluster) = gcp_cluster_isrunning(cluster)

# Interrupt cluster instances. If someone is not in "running" state, raise an exception.
# PUBLIC
function gcp_interrupt_cluster(cluster::Cluster)
    gcp_stop_instances(cluster)
    gcp_await_status(cluster.cluster_nodes, "stopped")
end

# PUBLIC
gcp_can_resume(cluster::Cluster) = gcp_cluster_status(cluster, ["stopped"])

# Start interrupted cluster instances or reboot running cluster instances.
# All instances must be in "interrupted" or "running" state.
# If some instance is not in "interrupted" or "running" state, raise an exception.
# PUBLIC
function gcp_resume_cluster(cluster::Cluster)
    gcp_start_instances(cluster)
    gcp_await_status(cluster, cluster.cluster_nodes, "RUNNING")
    gcp_await_check(cluster.cluster_nodes, "ok")
    for instance in keys(cluster.cluster_nodes)
        public_ip = Ec2.describe_instances(Dict("InstanceId" => cluster.cluster_nodes[instance]))["reservationSet"]["item"]["instancesSet"]["item"]["ipAddress"]
        try_run(`ssh -i /tmp/$(cluster.name) -o StrictHostKeyChecking=no ubuntu@$public_ip uptime`)
    end
end


# Check if the cluster instances are running or interrupted.
gcp_cluster_isrunning(cluster::Cluster) = gcp_cluster_status(cluster, ["RUNNING"]) && gcp_cluster_ready(cluster) 
gcp_cluster_isstopped(cluster::Cluster) = gcp_cluster_status(cluster, ["stopped"])

function gcp_stop_instances(cluster::Cluster)
    for id in values(cluster.cluster_nodes)
        Ec2.stop_instances(id)
    end
end

function gcp_start_instances(cluster::Cluster)
    for id in values(cluster.cluster_nodes)
        Ec2.start_instances(id)
    end
end

# PUBLIC
function gcp_get_ips(cluster::Cluster)
    ips = Dict()
    
    for i = 1:cluster.count
        node_name = cluster.name * string(i)
        ips[node_name] = gcp_get_ips_instance(cluster, node_name)
    end

    return ips
end

function gcp_get_instance_dict(cluster::Cluster, name)
    return JSON.parse(String(GCPAPI.compute(:Instance, :get, cluster.project, cluster.zone, name)))
end

function gcp_allow_ssh()
    #POST https://compute.googleapis.com/compute/beta/projects/cloudclusters/global/firewalls
#{"allowed":[{"ports":["22"]}],"direction":"INGRESS","kind":"compute#firewall","name":"allow-ssh","network":"projects/cloudclusters/global/networks/default","priority":1000,"selfLink":"projects/cloudclusters/global/firewalls/allow-ssh","sourceRanges":["0.0.0.0/0"]}
end