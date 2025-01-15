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
    instance_type_master::String
    instance_type_worker::String
    zone::String
    project::String
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    features::Dict{Symbol, Any}
end


mutable struct GCPPeerWorkers <: PeerWorkers # Cluster
    name::String
    source_image::String
    count::Int
    instance_type::String
    zone::String
    project::String
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    features::Dict{Symbol, Any}
end

mutable struct GCPPeerWorkersMPI <: PeerWorkersMPI # Cluster
    name::String
    source_image::String
    count::Int
    instance_type::String
    zone::String
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    features::Dict{Symbol, Any}
end

# PUBLIC
"""
Creates a compute instances cluster and returns it.
"""
function gcp_create_cluster(cluster::Cluster)
    return gcp_create_instances(cluster)
end


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

    return
end


#=
Grupo de Alocação
=#
# PUBLIC
function gcp_create_placement_group(name)
    @warn "CALLED NOT IMPLEMENTED METHOD!"
end

function gcp_delete_placement_group(name)
    @warn "CALLED NOT IMPLEMENTED METHOD!"
end

#=
Grupo de Segurança 
=#
# PUBLIC
function gcp_create_security_group(name, description)
    @warn "CALLED NOT IMPLEMENTED METHOD!"
end

function gcp_delete_security_group(id)
    @warn "CALLED NOT IMPLEMENTED METHOD!"
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
   run(`ssh-keygen -t rsa -b 2048 -f /tmp/$internal_key_name -C ubuntu -N ""`)
   run(`chmod 400 /tmp/$internal_key_name`)
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
    public_key = read("/tmp/$(cluster.name).pub", String)

    params_master = Vector{Dict}()

   push!(params_master, Dict(
    "disks" => [Dict(
        "autoDelete" => true,
        "boot" => true,
        "initializeParams" => Dict(
            "diskSizeGb" => 50,
            "sourceImage" => "projects/$(cluster.source_image_master)"
        ),
        "mode" => "READ_WRITE",
        "type" => "PERSISTENT"
    )],
    "zone" => cluster.zone,
    "machineType" => "zones/$(cluster.zone)/machineTypes/$(cluster.instance_type_master)",
    "name" => lowercase(cluster.name) * string(1),
    "networkInterfaces" => [Dict(
        "accessConfigs" => [Dict(
            "name" => "external-nat",
            "type" => "ONE_TO_ONE_NAT"
        )],
        "network" => "https://www.googleapis.com/compute/v1/projects/$(cluster.project)/global/networks/default"
    )],
    "metadata" => 
        "items" => [Dict(
            "key" => "startup-script",
            "value" => user_data_base64
        ), 
        Dict(
            "key" => "ssh-keys",
            "value" => "ubuntu:$public_key"
        )]
    ))

    params_workers = Vector{Dict}()

    for i = 1:cluster.count - 1
        push!(params_workers, Dict(
            "disks" => [Dict(
                "autoDelete" => true,
                "boot" => true,
                "initializeParams" => Dict(
                    "diskSizeGb" => 50,
                    "sourceImage" => "projects/$(cluster.source_image_worker)"
                ),
                "mode" => "READ_WRITE",
                "type" => "PERSISTENT"
            )],
            "zone" => cluster.zone,
            "machineType" => "zones/$(cluster.zone)/machineTypes/$(cluster.instance_type_worker)",
            "name" => lowercase(cluster.name) * string(i + 1),
            "networkInterfaces" => [Dict(
                "accessConfigs" => [Dict(
                    "name" => "external-nat",
                    "type" => "ONE_TO_ONE_NAT"
                )],
                "network" => "https://www.googleapis.com/compute/v1/projects/$(cluster.project)global/networks/default"
            )],
            "metadata" => 
                "items" => [Dict(
                    "key" => "startup-script",
                    "value" => user_data_base64
                ), 
                Dict(
                    "key" => "ssh-keys",
                    "value" => "ubuntu:$public_key"
                )]
        ))
    end

    return params_master, params_workers
end
 
function gcp_create_params(cluster::PeerWorkers, user_data_base64)
    public_key = read("/tmp/$(cluster.name).pub", String)

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
                "network" => "https://www.googleapis.com/compute/v1/projects/$(cluster.project)/global/networks/default"
            )],
            "metadata" => 
                "items" => [Dict(
                    "key" => "startup-script",
                    "value" => user_data_base64
                ), 
                Dict(
                    "key" => "ssh-keys",
                    "value" => "ubuntu:$public_key"
                )]
        ))
    end

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
end


#=
Cria as instâncias. 
=#


function gcp_create_instances(cluster::ManagerWorkers)
    new_cluster = cluster
    cluster_nodes = Dict()

    # Configurando a conexão SSH.
    internal_key_name, user_data = gcp_set_up_ssh_connection(cluster.name)

    try gcp_allow_ssh(cluster.project) catch end

    user_data_base64 = base64encode(user_data)

    # Criando as instâncias
    params_master, params_workers = gcp_create_params(cluster, user_data_base64)
    # Criar o headnode
    gcp_compute_instance_insert(new_cluster, params_master)
    cluster_nodes[Symbol("master1")] = lowercase(new_cluster.name) * string(1)

    # Criar os worker nodes.
    gcp_compute_instance_insert(new_cluster, params_workers)

    for i in 1:new_cluster.count - 1
        cluster_nodes[Symbol("worker$i")] = lowercase(new_cluster.name) * string(i + 1)
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

    try gcp_allow_ssh(cluster.project) catch end

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

    gcp_remove_temp_files(internal_key_name)

    return new_cluster
end

function gcp_compute_instance_insert(cluster::Cluster, params)
    vector_size = size(params, 1)
    for i = 1:vector_size
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

# PUBLIC
gcp_can_interrupt(cluster::Cluster) = gcp_cluster_isrunning(cluster)

# Interrupt cluster instances. If someone is not in "running" state, raise an exception.
# PUBLIC
function gcp_interrupt_cluster(cluster::Cluster)
    gcp_stop_instances(cluster)
    gcp_await_status(cluster, cluster.cluster_nodes, "stopped")
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

function gcp_add_to_common_metadata(cluster::Cluster, public_key)
    project_dict = JSON.parse(String(GCPAPI.compute(:Project, :get, cluster.project)))

    fingerprint = project_dict["commonInstanceMetadata"]["fingerprint"]

    existing_ssh_keys = ""

    items = get(project_dict["commonInstanceMetadata"], "items", [])
    for item in items
        if item["key"] == "ssh-keys"
            existing_ssh_keys = item["value"]
            break
        end
    end
    
    public_key = replace(public_key, r"[\x00-\x1F\x7F]" => "")
    existing_ssh_keys = replace(existing_ssh_keys, r"[\x00-\x1F\x7F]" => "")

    metadata_dict = JSON.parse("{
                                \"items\": [
                                {
                                \"key\": \"ssh-keys\",
                                \"value\": \"$existing_ssh_keys\\nubuntu:$public_key\"
                                }
                                ],
                                \"fingerprint\": \"$fingerprint\"
                                }")

    GCPAPI.compute(:Project, :setCommonInstanceMetadata, cluster.project; data=metadata_dict)
end

function gcp_allow_ssh(project)
    firewall_rule = Dict(
        "allowed" => [
            Dict("IPProtocol" => "tcp",
                "ports" => ["22"])],
        "direction" => "INGRESS",
        "kind" => "compute#firewall",
        "name" => "allow-ssh",
        "network" => "projects/$project/global/networks/default",
        "priority" => 1000,
        "selfLink" => "projects/$project/global/firewalls/allow-ssh",
        "sourceRanges" => ["0.0.0.0/0"]
    )

    GCPAPI.compute(:Firewall, :insert, project; data=firewall_rule)
end