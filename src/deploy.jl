
abstract type DeployMode end 
abstract type LinkMode <: DeployMode end
abstract type ClusterizeMode <: DeployMode end
abstract type CreateMode <: DeployMode end

struct ClusterHandle end 

# indexed by wid
cluster_deploy_info = Dict()
 
default_directory() = defaults_dict[:directory]
default_exename() = defaults_dict[:exename]
default_exeflags() = defaults_dict[:exeflags]
default_tunnel() = defaults_dict[:tunneled]                    # read from a CloudClousters.toml config file
#default_ident() = nothing                  # read from a CloudClousters.toml config file
#default_connect_ident() = nothing          # read from a CloudClousters.toml config file
default_threadlevel() = defaults_dict[:threadlevel]
default_mpiflags() = defaults_dict[:mpiflags]
default_sshflags() = defaults_dict[:sshflags]

function cluster_deploy(contract_handle)

    cluster_handle = create_sym(15)

    cluster_type, cluster_features = cluster_contract[contract_handle]
    instance_type = cluster_contract_resolved[contract_handle]
    @info "INSTANCE TYPE: $instance_type"
    cluster_provider = cluster_features[:node_provider]

    pids = cluster_deploy(cluster_provider, cluster_type, cluster_handle, cluster_features, instance_type)

    cluster_deploy_info[cluster_handle] = Dict(:pids => pids, :cluster_type => cluster_type, :instance_type => instance_type, :cluster_features => cluster_features)

    return cluster_handle
end

function cluster_deploy(cluster_provider, cluster_type::Type{<:ManagerWorkers}, cluster_handle, cluster_features, instance_type)

    instance_type_master, instance_type_worker = instance_type

    ip_master, user_id, nw = deploy_cluster(cluster_provider, cluster_type, CreateMode, cluster_handle, cluster_features, instance_type_master, instance_type_worker)
    
    manager_features = Dict(get(cluster_features, :manager_features, cluster_features))
    worker_features = Dict(get(cluster_features, :worker_features, cluster_features))

    exeflags_master = get(manager_features, :exeflags, default_exeflags()) |> x -> Cmd(convert(Vector{String}, split(x)))
    exeflags_worker = get(worker_features, :exeflags, default_exeflags()) |> x -> Cmd(convert(Vector{String}, split(x)))

    exename_master = get(manager_features, :exename, default_exename()) |> x -> Cmd(convert(Vector{String}, split(x)))
    exename_worker = get(worker_features, :exename, default_exename()) |> x -> Cmd(convert(Vector{String}, split(x)))

    directory_master = get(cluster_features, :directory, default_directory())
    directory_worker = get(cluster_features, :directory, default_directory())

    # only master
    tunnel = get(cluster_features, :tunnel, default_tunnel()) 
    #ident = get(cluster_features, :ident, default_ident()) 
    #connect_idents = get(cluster_features, :security_group_id, default_connect_ident()) 
    sshflags = get(cluster_features, :sshflags, default_sshflags()) |> x -> Cmd(convert(Vector{String}, split(x)))

    # only worker
    threadlevel = get(cluster_features, :threadlevel, default_threadlevel()) 
    mpiflags = get(cluster_features, :mpiflags, default_mpiflags()) |> x -> Cmd(convert(Vector{String}, split(x)))

    @info "count=$nw"
    @info "user_id=$user_id"
    @info "sshflags=$sshflags"
    @info "exename_master=$exename_master"
    @info "exeflags_master=$exeflags_master"
    @info "tunnel=$tunnel"
    @info "directory_master=$directory_master"
    @info "===> $user_id@$(ip_master[:public_ip])"

    master_id = nothing
    ntries = 1
    successfull = false
    while !successfull
        try
            master_id = addprocs(["$user_id@$(ip_master[:public_ip])"], exeflags=exeflags_master, dir=directory_master, sshflags=sshflags, exename=exename_master, tunnel=tunnel #=, ident=ident, connect_idents=connect_idents=#)
            successfull = true
            @info "master deployed ... $ntries attempts"
        catch e
            @error e
            rmprocs(2)
            @info "error - master deploy -- try $ntries"            
            ntries > 10 && throw(e)
        end
        ntries += 1
    end

    @everywhere master_id @eval using MPIClusterManagers
    @everywhere master_id @eval using CloudClusters

    @info "master_tcp_interface=$(ip_master[:private_ip])"
    @info "exename_worker=$exename_worker"
    @info "exeflags_worker=$exeflags_worker"
    @info "dir=$directory_worker"
    @info "threadlevel=$(Symbol(threadlevel))"
    @info "mpiflags=$mpiflags"
    @info "tunnel=$tunnel"

    successfull = false
    ntries = 1
    while !successfull
        try
            @fetchfrom master_id[1] addprocs(MPIWorkerManager(nw); master_tcp_interface=ip_master[:private_ip], dir=directory_worker, threadlevel=Symbol(threadlevel), mpiflags=mpiflags, exename=exename_worker, exeflags=exeflags_worker)
            successfull = true
            @info "workers deployed ... $ntries attempts"
        catch e 
            @info "error - workers deploy -- try $ntries"
            ntries > 10 && throw(e)
        end
        ntries += 1
    end

    return master_id

end

function cluster_deploy(cluster_provider, cluster_type::Type{<:PeerWorkers}, cluster_handle, cluster_features, instance_type)

    cluster_provider = cluster_features[:node_provider]

    ips, user_id = deploy_cluster(cluster_provider, cluster_type, CreateMode, cluster_handle, cluster_features, instance_type)
    
    sshflags = get(cluster_features, :sshflags, default_sshflags()) |> x -> Cmd(convert(Vector{String}, split(x)))
    exeflags = get(cluster_features, :exeflags, default_exeflags()) |> x -> Cmd(convert(Vector{String}, split(x)))
    exename = get(cluster_features, :exename, default_exename()) |> x -> Cmd(convert(Vector{String}, split(x)))
    directory = get(cluster_features, :directory, default_directory()) 
    tunnel = get(cluster_features, :tunnel, default_tunnel()) 
    #ident = get(cluster_features, :ident, default_ident())
    #connect_idents = get(cluster_features, :security_group_id, default_connect_ident()) 

    @info "sshflags=$sshflags"
    @info "exename=$exename"
    @info "exeflags=$exeflags"
    @info "tunnel=$tunnel"
    @info "directory=$directory"
    
    peer_ids = nothing
    ntries = 1
    successfull = false
    while !successfull
        try
            peer_ids = addprocs(["$user_id@$(ip[:public_ip])" for ip in values(ips)], exeflags=`$exeflags`, dir=directory, sshflags=sshflags, exename=exename, tunnel=tunnel#=, ident=ident, connect_idents=connect_idents=#)
            successfull = true
            @info "peers deployed ... $ntries attempts"
        catch e
            @info "error - peers deploy -- try $ntries"
            ntries > 10 && throw(e)
        end
        ntries += 1
    end

    return peer_ids

end

function cluster_interrupt(cluster_handle)
    interrupt_cluster(cluster_deploy_info[cluster_handle][:cluster_features][:node_provider], cluster_handle)
end

function cluster_resume(cluster_handle)
    resume_cluster(cluster_deploy_info[cluster_handle][:cluster_features][:node_provider], cluster_handle)
end

function cluster_terminate(cluster_handle)
    for pid in cluster_deploy_info[cluster_handle][:pids]
        rmprocs(pid)
    end
    terminate_cluster(cluster_deploy_info[cluster_handle][:cluster_features][:node_provider], cluster_handle)
end