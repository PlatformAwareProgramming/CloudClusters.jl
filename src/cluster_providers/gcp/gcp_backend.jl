using Random
using AWS: @service
using Serialization
using Base64
using Sockets

using JSON

import GoogleCloud as GCPAPI

gcp_session = Ref{Any}(nothing)

function gcp_check_session()
   if isnothing(gcp_session[])
      # Creates a GCP session and stores it.
      gcp_session[] = GCPAPI.GoogleSession(ENV["GOOGLE_APPLICATION_CREDENTIALS"], ["cloud-platform"])
      GCPAPI.set_session!(GCPAPI.compute, gcp_session[])    
   end
end


#=
Estrutura para Armazenar as informações e função de criação do cluster
=#

mutable struct GCPManagerWorkers <: ManagerWorkers #Cluster
    name::String
    image_id_manager::String
    image_id_worker::String
    count::Int
    instance_type_manager::String
    instance_type_worker::String
    user_manager::String
    user_worker::String
    zone::String
    project::String
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    features::Dict{Symbol, Any}
end


mutable struct GCPPeerWorkers <: PeerWorkers # Cluster
    name::String
    image_id::String
    count::Int
    instance_type::String
    user::String
    zone::String
    project::String
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    features::Dict{Symbol, Any}
end

mutable struct GCPPeerWorkersMPI <: PeerWorkersMPI # Cluster
    name::String
    image_id::String
    count::Int
    instance_type::String
    user::String
    zone::String
    project::String
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    features::Dict{Symbol, Any}
end

# PUBLIC
"""
Creates a compute instances cluster and returns it.
"""
function gcp_create_cluster(cluster::Cluster)
    gcp_check_session()
    cluster.cluster_nodes = gcp_create_instances(cluster)
    cluster
end


function gcp_get_ips_instance(cluster::Cluster, name) 
    public_ip = gcp_get_instance_dict(cluster, name)["networkInterfaces"][1]["accessConfigs"][1]["natIP"]
    private_ip = gcp_get_instance_dict(cluster, name)["networkInterfaces"][1]["networkIP"]
    
    return Dict(:public_ip => public_ip, :private_ip => private_ip)
end

# PUBLIC
function gcp_terminate_cluster(cluster::Cluster)
    gcp_delete_instances(cluster) 
    gcp_await_status(cluster, cluster.cluster_nodes, "notfound")
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
function gcp_set_up_ssh_connection(cluster_name, comment)   

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
  
function gcp_get_user_data(cluster_name, user, private_key, public_key)

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
sudo sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 1000/g' /etc/ssh/sshd_config
sudo sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 100/g' /etc/ssh/sshd_config
sudo systemctl restart ssh
"

   return user_data
end

function gcp_create_params(cluster::ManagerWorkers, cluster_nodes, internal_key_name, user_data, private_key, public_key)

    user_data_manager, user_data_worker = user_data

    ssh_path = joinpath(homedir(), ".ssh")
    pubpath = joinpath(ssh_path, "$internal_key_name.key.pub")

    params_manager = Vector{Dict}()

    user_manager = cluster.user_manager
    user_worker = cluster.user_worker

   push!(params_manager, Dict(
    "disks" => [Dict(
        "autoDelete" => true,
        "boot" => true,
        "initializeParams" => Dict(
            "diskSizeGb" => 50,
            "sourceImage" => "projects/$(cluster.image_id_manager)"
        ),
        "mode" => "READ_WRITE",
        "type" => "PERSISTENT"
    )],
    "zone" => cluster.zone,
    "machineType" => "zones/$(cluster.zone)/machineTypes/$(cluster.instance_type_manager)",
    "name" => cluster_nodes[:manager], 
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
            "value" => user_data_manager
        ), 
        Dict(
            "key" => "ssh-keys",
            "value" => "$user_manager:$pubpath"
        )]
    ))

    params_workers = Vector{Dict}()

    for i = 1:cluster.count 
        push!(params_workers, Dict(
            "disks" => [Dict(
                "autoDelete" => true,
                "boot" => true,
                "initializeParams" => Dict(
                    "diskSizeGb" => 50,
                    "sourceImage" => "projects/$(cluster.image_id_worker)"
                ),
                "mode" => "READ_WRITE",
                "type" => "PERSISTENT"
            )],
            "zone" => cluster.zone,
            "machineType" => "zones/$(cluster.zone)/machineTypes/$(cluster.instance_type_worker)",
            "name" =>  cluster_nodes[Symbol("worker$i")], 
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
                    "value" => user_data_worker
                ), 
                Dict(
                    "key" => "ssh-keys",
                    "value" => "$user_worker:$pubpath"
                )]
        ))
    end

    return params_manager, params_workers
end
 
function gcp_create_params(cluster::PeerWorkers, cluster_nodes, internal_key_name, user_data, private_key, public_key)

    ssh_path = joinpath(homedir(), ".ssh")
    pubpath = joinpath(ssh_path, "$internal_key_name.key.pub")

    user = cluster.user

    params = Vector{Dict}()
    
    for instance in values(cluster_nodes)
        push!(params, Dict(
            "disks" => [Dict(
                "autoDelete" => true,
                "boot" => true,
                "initializeParams" => Dict(
                    "diskSizeGb" => 50,
                    "sourceImage" => "projects/$(cluster.image_id)"
                ),
                "mode" => "READ_WRITE",
                "type" => "PERSISTENT"
            )],
            "zone" => cluster.zone,
            "machineType" => "zones/$(cluster.zone)/machineTypes/$(cluster.instance_type)",
            "name" => instance,
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
                    "value" => user_data
                ), 
                Dict(
                    "key" => "ssh-keys",
                    "value" => "$user:$pubpath"
                )]
        ))
    end

    return params
end

function gcp_remove_temp_files(internal_key_name)
    ssh_path = joinpath(homedir(), ".ssh")
    keypath = joinpath(ssh_path, "$internal_key_name.key")
    pubpath = joinpath(ssh_path, "$internal_key_name.key.pub")
    rm(keypath)
    rm(pubpath)
end

function gcp_set_hostfile(cluster::Cluster, cluster_nodes, internal_key_name, user)
    gcp_set_hostfile(cluster, cluster_nodes, internal_key_name, user, user)
end

 
function gcp_set_hostfile(cluster::Cluster, cluster_nodes, internal_key_name, user_manager, user_worker)

    # Testando se a conexão SSH está ativa.
    for (name, instance) in cluster_nodes
        public_ip = gcp_get_ips_instance(cluster, instance)[:public_ip]
        connection_ok = false
        print("Waiting for $name to become accessible .")
        while !connection_ok
            try
                connect(public_ip, 22)
                connection_ok = true
            catch e
                print(".")                
            end
        end
        println("ok")                
    end

    # Criando o arquivo hostfile.
    hostfile_content = "127.0.0.1 localhost\n"
    hostfilefile_content = ""
    for (name, instance) in cluster_nodes
        private_ip = gcp_get_ips_instance(cluster, instance)[:private_ip]
        hostfile_content *= "$private_ip $instance\n"
        if name != :manager
           hostfilefile_content *= "$instance\n"
        end
    end

    ssh_path = joinpath(homedir(), ".ssh")
    keypath = joinpath(ssh_path, "$internal_key_name.key")

    home = ENV["HOME"]

    # Atualiza o hostname e o hostfile.
    for (name, instance) in cluster_nodes
        user = name == :manager ? user_manager : user_worker
        public_ip = gcp_get_ips_instance(cluster, instance)[:public_ip]
        run(`ssh-keygen -f $home/.ssh/known_hosts -R $public_ip`)
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
end


#=
Cria as instâncias. 
=#


function gcp_create_instances(cluster::ManagerWorkers)

    new_cluster = cluster

    cluster_nodes = Dict()

    cluster_nodes[:manager] = lowercase(new_cluster.name) * string(1)
    for i in 1:new_cluster.count
        cluster_nodes[Symbol("worker$i")] = lowercase(new_cluster.name) * string(i + 1)
    end

    # Configurando a conexão SSH.
    
    private_key, public_key = gcp_set_up_ssh_connection(cluster.name, cluster.user_manager)

    user_data_manager = gcp_get_user_data(cluster.name, cluster.user_manager, private_key, public_key)
    user_data_worker = gcp_get_user_data(cluster.name, cluster.user_worker, private_key, public_key)

    internal_key_name = cluster.name

    try gcp_allow_ssh(cluster.project) catch end

    # Criando as instâncias
    params_manager, params_workers = gcp_create_params(cluster, cluster_nodes, internal_key_name, (user_data_manager, user_data_worker), private_key, public_key)

    # Criar o headnode
    gcp_compute_instance_insert(new_cluster, params_manager)

    # Criar os worker nodes.
    gcp_compute_instance_insert(new_cluster, params_workers)

    gcp_await_status(new_cluster, cluster_nodes, "RUNNING")

    gcp_set_hostfile(new_cluster, cluster_nodes, internal_key_name, cluster.user_manager, cluster.user_worker)

    #gcp_remove_temp_files(internal_key_name)

    return cluster_nodes
end

function gcp_create_instances(cluster::PeerWorkers)

    new_cluster = cluster

    cluster_nodes = Dict()
    for i = 1:new_cluster.count
        cluster_nodes[Symbol("peer$i")] = lowercase(new_cluster.name) * string(i)
    end

    # Configurando a conexão SSH.
    private_key, public_key = gcp_set_up_ssh_connection(cluster.name, cluster.user)
    user_data = gcp_get_user_data(cluster.name, cluster.user, private_key, public_key)

    internal_key_name = cluster.name

    try gcp_allow_ssh(cluster.project) catch end

    # Criando as instâncias
    params = gcp_create_params(new_cluster, cluster_nodes, internal_key_name, user_data, private_key, public_key)

    # Criar os Peers.
    gcp_compute_instance_insert(new_cluster, params)

    gcp_await_status(new_cluster, cluster_nodes, "RUNNING")

    gcp_set_hostfile(new_cluster, cluster_nodes, internal_key_name, cluster.user)

    #gcp_remove_temp_files(internal_key_name)

    return cluster_nodes
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
        current_status = gcp_get_instance_status(cluster, cluster_nodes[nodeid])
        while current_status != status
            print(".")
            sleep(2)
            current_status = gcp_get_instance_status(cluster, cluster_nodes[nodeid])
        end
        println("successfull")
    end
end

# PUBLIC
function gcp_cluster_status(cluster::Cluster, status_list)
    cluster_nodes = cluster.cluster_nodes
    for nodeid in values(cluster_nodes)
        current_status = gcp_get_instance_status(cluster, nodeid)
        !(current_status in status_list) && return false
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
    gcp_await_status(cluster, cluster.cluster_nodes, "TERMINATED")
end

# PUBLIC
gcp_can_resume(cluster::Cluster) = gcp_cluster_status(cluster, ["TERMINATED"])

# Start interrupted cluster instances or reboot running cluster instances.
# All instances must be in "interrupted" or "running" state.
# If some instance is not in "interrupted" or "running" state, raise an exception.
# PUBLIC
function gcp_resume_cluster(cluster::ManagerWorkers)
    home = ENV["HOME"]
    ssh_path = joinpath(homedir(), ".ssh")
    keypath = joinpath(ssh_path, "$(cluster.name).key")
    user_manager = cluster.user_manager
    user_worker = cluster.user_worker

    gcp_start_instances(cluster)
    gcp_await_status(cluster, cluster.cluster_nodes, "RUNNING")

    public_ip = gcp_get_ips_instance(cluster, cluster.cluster_nodes[:manager])[:public_ip]

    run(`ssh-keygen -f $home/.ssh/known_hosts -R $public_ip`)
    try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user_manager@$public_ip uptime`)

    for i in 1:cluster.count
        instance = cluster.cluster_nodes[Symbol("worker$i")]
        public_ip = gcp_get_ips_instance(cluster, instance)[:public_ip]
        run(`ssh-keygen -f $home/.ssh/known_hosts -R $public_ip`)
        try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user_worker@$public_ip uptime`)
    end
end

function gcp_resume_cluster(cluster::PeerWorkers)
    home = ENV["HOME"]
    ssh_path = joinpath(homedir(), ".ssh")
    keypath = joinpath(ssh_path, "$(cluster.name).key")
    user = cluster.user

    gcp_start_instances(cluster)
    gcp_await_status(cluster, cluster.cluster_nodes, "RUNNING")

    for instance in values(cluster.cluster_nodes)
        public_ip = gcp_get_ips_instance(cluster, instance)[:public_ip]
        run(`ssh-keygen -f $home/.ssh/known_hosts -R $public_ip`)
        try_run(`ssh -i $keypath -o StrictHostKeyChecking=no $user@$public_ip uptime`)
    end
end

# Check if the cluster instances are running or interrupted.
gcp_cluster_isrunning(cluster::Cluster) = gcp_cluster_status(cluster, ["RUNNING"]) #&& gcp_cluster_ready(cluster) 
gcp_cluster_isstopped(cluster::Cluster) = gcp_cluster_status(cluster, ["TERMINATED"])

function gcp_stop_instances(cluster::Cluster)
    for id in values(cluster.cluster_nodes)
        GCPAPI.compute(:Instance, :stop, cluster.project, cluster.zone, id)
    end
end

function gcp_start_instances(cluster::Cluster)
    for id in values(cluster.cluster_nodes)
        GCPAPI.compute(:Instance, :start, cluster.project, cluster.zone, id)
    end
end

# PUBLIC
function gcp_get_ips(cluster::Cluster)
    ips = Dict()
    for (node, id) in cluster.cluster_nodes
         ips[node] = gcp_get_ips_instance(cluster, id) 
    end
    ips
end

function gcp_get_instance_dict(cluster::Cluster, name)
    gcp_check_session()
    return JSON.parse(String(GCPAPI.compute(:Instance, :get, cluster.project, cluster.zone, name)))
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