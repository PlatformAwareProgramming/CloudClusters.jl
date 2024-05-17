
abstract type DeployMode end 
abstract type LinkMode <: DeployMode end
abstract type ClusterizeMode <: DeployMode end
abstract type CreateMode <: DeployMode end

struct ClusterHandle end 

# indexed by wid
cluster_deploy_info = Dict()
 
default_exename() = defaults_dict[:exename]
default_exeflags() = defaults_dict[:exeflags]
default_tunnel() = defaults_dict[:tunneled]                    # read from a CloudClousters.toml config file
#default_ident() = nothing                  # read from a CloudClousters.toml config file
#default_connect_ident() = nothing          # read from a CloudClousters.toml config file
default_threadlevel() = defaults_dict[:threadlevel]
default_mpiflags() = defaults_dict[:mpiflags]

function cluster_deploy(contract_handle)

    cluster_handle = gensym()

    cluster_type, cluster_features = cluster_contract[contract_handle]
    instance_type = cluster_contract_resolved[contract_handle]
    cluster_provider = cluster_features[:node_provider]

    pids = cluster_deploy(cluster_provider, cluster_type, cluster_handle, cluster_features, instance_type)

    cluster_deploy_info[cluster_handle] = pids

    return cluster_handle => pids
end

function cluster_deploy(cluster_provider, cluster_type::Type{<:ManagerWorkers}, cluster_handle, cluster_features, instance_type)

    instance_type_master, instance_type_worker = instance_type

    #ip_master, nw, user_id, keyname = deploy_cluster(cluster_provider, cluster_type, CreateMode, cluster_handle, cluster_features, instance_type_master, instance_type_worker)
    ip_master = Dict()
    ip_master[:public_ip] = "127.0.0.1"
    ip_master[:private_ip] = "127.0.0.1"
    nw = 4
    user_id = "heron"
    keyname = "/home/heron/hpc-shelf-credential.pem"

    manager_features = Dict(get(cluster_features, :manager_features, cluster_features))
    worker_features = Dict(get(cluster_features, :worker_features, cluster_features))

    exeflags_master = get(manager_features, :exeflags, default_exeflags())
    exeflags_worker = get(worker_features, :exeflags, default_exeflags())

    exename_master = get(manager_features, :exename, default_exename())
    exename_worker = get(worker_features, :exename, default_exename())

    tunnel = get(cluster_features, :tunnel, default_tunnel()) 
    #ident = get(cluster_features, :ident, default_ident()) 
    #connect_idents = get(cluster_features, :security_group_id, default_connect_ident()) 
    threadlevel = get(cluster_features, :threadlevel, default_threadlevel()) 
    mpiflags = get(cluster_features, :mpiflags, default_mpiflags()) 
    
    master_id = addprocs(["$user_id@$(ip_master[:public_ip])"]; sshflags="-i $keyname", exename=exename_master, exeflags=exeflags_master, tunnel=tunnel #=, ident=ident, connect_idents=connect_idents=#)
    @everywhere [master_id[1]] @eval using CloudClusters
    @fetchfrom master_id[1] addprocs(MPIWorkerManager(nw); master_tcp_interface=ip_master[:private_ip], threadlevel=threadlevel, mpiflags=mpiflags, exename = exename_worker, exeflags=exeflags_worker)

    return master_id[1]
end

function cluster_deploy(cluster_provider, cluster_type::Type{<:PeerWorkers}, cluster_handle, cluster_features, instance_type)

    cluster_provider = cluster_features[:node_provider]

    #ips, user_id, keyname = deploy_cluster(cluster_provider, cluster_type, CreateMode, cluster_handle, cluster_features, instance_type)
    ips = [Dict(:public_ip => "127.0.0.1", :private_ip => "127.0.0.1"), 
           Dict(:public_ip => "127.0.0.1", :private_ip => "127.0.0.1"), 
           Dict(:public_ip => "127.0.0.1", :private_ip => "127.0.0.1"), 
           Dict(:public_ip => "127.0.0.1", :private_ip => "127.0.0.1")]
    user_id = "heron"
    keyname = "/home/heron/hpc-shelf-credential.pem"

    exeflags = get(cluster_features, :exeflags, default_exeflags()) 
    exename = get(cluster_features, :exename, default_exename())
    tunnel = get(cluster_features, :tunnel, default_tunnel())
    #ident = get(cluster_features, :ident, default_ident())
    #connect_idents = get(cluster_features, :security_group_id, default_connect_ident()) 

    peer_ids = addprocs(["$user_id@$(ip[:public_ip])" for ip in ips], sshflags="-i $keyname", exename=exename, exeflags=exeflags, tunnel=tunnel#=, ident=ident, connect_idents=connect_idents=#)

    return peer_ids
end

function cluster_interrupt(wid)
    interrupt_cluster(cluster_deploy_info[wid][:cluster_provider], cluster_deploy_info[wid])
end

function cluster_resume(wid)
    resume_cluster(cluster_deploy_info[wid][:cluster_provider], cluster_deploy_info[wid])
end

function cluster_terminate(wid)
    terminate_cluster(cluster_deploy_info[wid][:cluster_provider], cluster_deploy_info[wid])
end