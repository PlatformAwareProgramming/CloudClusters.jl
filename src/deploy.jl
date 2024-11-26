
abstract type DeployMode end 
abstract type LinkMode <: DeployMode end
abstract type ClusterizeMode <: DeployMode end
abstract type CreateMode <: DeployMode end

struct ClusterHandle end 

# indexed by wid
cluster_deploy_info = Dict()
 
# read defaults from a CloudClousters.toml config file
default_directory(provider_type) = defaults_dict[provider_type][:directory]
default_exename(provider_type) = defaults_dict[provider_type][:exename]
default_exeflags(provider_type) = defaults_dict[provider_type][:exeflags]
default_tunnel(provider_type) = defaults_dict[provider_type][:tunneled]                    
#default_ident() = nothing                  
#default_connect_ident() = nothing          
default_threadlevel(provider_type) = defaults_dict[provider_type][:threadlevel]
default_mpiflags(provider_type) = defaults_dict[provider_type][:mpiflags]
default_sshflags(provider_type) = defaults_dict[provider_type][:sshflags]

function extract_mwfeature(cluster_features, provider_type, featureid)
    if haskey(cluster_features, :manager_features) &&
      haskey(cluster_features, :worker_features) &&
      haskey(cluster_features[:manager_features], featureid) &&
      haskey(cluster_features[:worker_features], featureid) &&
     !haskey(cluster_features, featureid) 
      feature_manager = cluster_features[:manager_features][featureid]     
      feature_worker = cluster_features[:worker_features][featureid]     
    elseif haskey(cluster_features, featureid) 
      feature_manager = feature_worker = cluster_features[featureid]     
    else
      feature_manager = feature_worker = defaults_dict[provider_type][featureid]    
    end
    return feature_manager, feature_worker
  end

  
function cluster_deploy(contract_handle, config_args...)

    !is_contract(contract_handle) && error("The symbol $contract_handle is not a contract handle")
    !is_resolved(contract_handle) && error("The contract $contract_handle is not resolved. Run '@resolve $contract_handle' to resolve it before deploy.")

    more_cluster_features = Dict{Symbol, Any}(config_args)
    
    cluster_handle = create_sym(15)

    cluster_type, cluster_features = cluster_contract[contract_handle]

    cluster_features = merge_features(cluster_features, more_cluster_features) 

    instance_type = cluster_contract_resolved[contract_handle]

    cluster_deploy_info[cluster_handle] = Dict(:pids => Vector{Int}(), :features => cluster_features)
 
    pids = nothing
    try
        pids = cluster_deploy(cluster_type, cluster_handle, cluster_features, instance_type)
    catch e
        @warn "some error deploying cluster $cluster_handle ($e)"
    end

    if !isnothing(pids) 
        cluster_deploy_info[cluster_handle][:pids] = pids
        @info "pids: $(cluster_deploy_info[cluster_handle][:pids])"
        return cluster_handle
    else
       @warn "error launching processes -- cluster will be terminated"
       cluster_terminate(cluster_handle)
       @error "deployment failed due to an unrecoverable error in launching processes"
       return nothing
    end

end

function merge_features(cluster_features, more_cluster_features)

  # TODO !
  #  haskey(cluster_features, :manager_features) && haskey(more_cluster_features, :manager_features)  && merge!(cluster_features[:manager_features], more_cluster_features[:manager_features])
  #  haskey(cluster_features, :worker_features) && haskey(more_cluster_features, :worker_features)  && merge!(cluster_features[:worker_features], more_cluster_features[:worker_features])
  #  haskey(cluster_features, :manager_features) && !haskey(more_cluster_features, :manager_features)  && 

  merged_cluster_features = merge(cluster_features, more_cluster_features)

  if haskey(cluster_features, :manager_features) && haskey(more_cluster_features, :manager_features)
     merged_cluster_features[:manager_features] = merge(cluster_features[:manager_features], more_cluster_features[:manager_features])
  end

  if haskey(cluster_features, :worker_features) && haskey(more_cluster_features, :worker_features)
    merged_cluster_features[:worker_features] = merge(cluster_features[:worker_features], more_cluster_features[:worker_features])
  end

  return merged_cluster_features
end

function cluster_deploy(cluster_type::Type{<:ManagerWorkers}, cluster_handle, cluster_features, instance_type)

    cluster_provider = cluster_features[:node_provider]

    instance_type_manager, instance_type_worker = instance_type

#    cluster_deploy_info[cluster_handle] = Dict(:features => cluster_features)

    deploy_cluster(cluster_provider, cluster_type, CreateMode, cluster_handle, cluster_features, (instance_type_manager, instance_type_worker))
    
    ips = get_ips(cluster_provider, cluster_handle)
    launch_processes(cluster_provider, cluster_type, cluster_handle, ips)
end

function launch_processes_ssh(cluster_features, _::Type{<:ManagerWorkers}, ips)

    user = get_user(cluster_features)
    cluster_provider = cluster_features[:node_provider]

    ip_manager = ips[:manager]

    manager_features = Dict(get(cluster_features, :manager_features, cluster_features))
    worker_features = Dict(get(cluster_features, :worker_features, cluster_features))

    exeflags_manager = get(manager_features, :exeflags, default_exeflags(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))
    exeflags_worker = get(worker_features, :exeflags, default_exeflags(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))

    exename_manager = get(manager_features, :exename, default_exename(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))
    exename_worker = get(worker_features, :exename, default_exename(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))

    directory_manager = get(cluster_features, :directory, default_directory(cluster_provider))
    directory_worker = get(cluster_features, :directory, default_directory(cluster_provider))

    # only manager
    tunnel = get(cluster_features, :tunnel, default_tunnel(cluster_provider)) 
    #ident = get(cluster_features, :ident, default_ident()) 
    #connect_idents = get(cluster_features, :security_group_id, default_connect_ident()) 
    sshflags = get(cluster_features, :sshflags, default_sshflags(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))

    # only worker
    threadlevel = get(cluster_features, :threadlevel, default_threadlevel(cluster_provider)) 
    mpiflags = get(cluster_features, :mpiflags, default_mpiflags(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))

    #= FOR DEBUGGING
    @info "user_id=$user_id"
    @info "sshflags=$sshflags"
    @info "exename_manager=$exename_manager"
    @info "exeflags_manager=$exeflags_manager"
    @info "tunnel=$tunnel"
    @info "directory_manager=$directory_manager"
    @info "===> $user_id@$(ip_manager[:public_ip])" 
    =#

    master_id = nothing
    ntries = 1
    successfull = false
    while !successfull
        try
            master_id = addprocs(["$user@$(ip_manager[:public_ip])"], exeflags=exeflags_manager, dir=directory_manager, sshflags=sshflags, exename=exename_manager, tunnel=tunnel #=, ident=ident, connect_idents=connect_idents=#)
            successfull = true
            @info "master deployed ... $ntries attempts"
        catch e
            report_exception(e)
            @info "error - master deploy -- try $ntries"            
            ntries > 10 && throw(e)
        end
        ntries += 1
    end

    @everywhere master_id @eval using MPIClusterManagers
    #@everywhere master_id @eval using CloudClusters

   nw = get(cluster_features, :node_count, 1)
   ppw =  get(cluster_features, :node_process_count, 1)
   np = nw * ppw;

   #= FOR DEBUGGING
    @info "master_tcp_interface=$(ip_manager[:private_ip])"
    @info "exename_worker=$exename_worker"
    @info "exeflags_worker=$exeflags_worker"
    @info "dir=$directory_worker"
    @info "threadlevel=$(Symbol(threadlevel))"
    @info "mpiflags=$mpiflags"
    @info "tunnel=$tunnel" 
    @info "count=$nw -- $(typeof(nw))"
   =#

    successfull = false
    ntries = 1
    while !successfull
        try
            remotecall_fetch(addprocs, master_id[1], MPIWorkerManager(np), master_tcp_interface=ip_manager[:private_ip], dir=directory_worker, threadlevel=Symbol(threadlevel), mpiflags=mpiflags, exename=exename_worker, exeflags=exeflags_worker)

            # the alterenative below fails
#           @fetchfrom master_id[1] addprocs(MPIWorkerManager(nw); master_tcp_interface=ip_manager[:private_ip], dir=directory_worker, threadlevel=Symbol(threadlevel), mpiflags=mpiflags, exename=exename_worker, exeflags=exeflags_worker)

            successfull = true
            @info "workers deployed ... $ntries attempts"
        catch e 
            report_exception(e)
            @info "error - workers deploy -- try $ntries"
            ntries > 10 && throw(e)
        end
        ntries += 1
    end

    return master_id

end


function launch_processes_local(cluster_features, _::Type{<:ManagerWorkers}, ips)

    nw =  get(cluster_features, :node_count, 1)

    master_id = nothing
    ntries = 1
    successfull = false
    while !successfull
        try
            master_id = addprocs(1)
            successfull = true
            @info "master deployed locally ... $ntries attempts"
        catch e
            report_exception(e)
            @info "error - master deploy locally -- try $ntries"            
            ntries > 10 && throw(e)
        end
        ntries += 1
    end

    @everywhere master_id @eval using MPIClusterManagers
   # @everywhere master_id @eval using CloudClusters

    threadlevel = get(cluster_features, :threadlevel, default_threadlevel(Localhost)) 
    mpiflags = get(cluster_features, :mpiflags, default_mpiflags(Localhost)) |> x -> Cmd(convert(Vector{String}, split(x)))

    successfull = false
    ntries = 1
    while !successfull
        try
            remotecall_fetch(addprocs, master_id[1], MPIWorkerManager(nw), threadlevel=Symbol(threadlevel), mpiflags=mpiflags)
            successfull = true
            @info "workers deployed locally ... $ntries attempts --- $mpiflags"
        catch e 
            report_exception(e)
            @info "error - workers deploy locally -- try $ntries"
            ntries > 10 && throw(e)
        end
        ntries += 1
    end

    return master_id

end


function cluster_deploy(cluster_type::Type{<:PeerWorkers}, cluster_handle, cluster_features, instance_type)

    cluster_provider = cluster_features[:node_provider]

    deploy_cluster(cluster_provider, cluster_type, CreateMode, cluster_handle, cluster_features, instance_type)

    ips = get_ips(cluster_provider, cluster_handle)
    launch_processes(cluster_provider, cluster_type, cluster_handle, ips)  
end

function launch_processes_ssh(cluster_features, _::Type{<:PeerWorkers}, ips)

    cluster_provider = cluster_features[:node_provider]

    user = get_user(cluster_features)
    sshflags = get(cluster_features, :sshflags, default_sshflags(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))
    exeflags = get(cluster_features, :exeflags, default_exeflags(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))
    exename = get(cluster_features, :exename, default_exename(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))
    directory = get(cluster_features, :directory, default_directory(cluster_provider)) 
    tunnel = get(cluster_features, :tunnel, default_tunnel(cluster_provider)) 
    #ident = get(cluster_features, :ident, default_ident())
    #connect_idents = get(cluster_features, :security_group_id, default_connect_ident()) 

    ppw =  get(cluster_features, :node_process_count, 1)

    #@info "sshflags=$sshflags"
    #@info "exename=$exename"
    #@info "exeflags=$exeflags"
    #@info "tunnel=$tunnel"
    #@info "directory=$directory"
    
    peer_ids = nothing
    ntries = 1
    successfull = false
    while !successfull
        try
            peer_ids = addprocs(["$user@$(ip[:public_ip])" for ip in values(ips) for _ in 1:ppw], exeflags=`$exeflags`, dir=directory, sshflags=sshflags, exename=exename, tunnel=tunnel#=, ident=ident, connect_idents=connect_idents=#)
            successfull = true
            @info "peers deployed ... $ntries attempts"
        catch e
            report_exception(e)
            @info "error - peers deploy -- try $ntries"
            ntries > 10 && throw(e)
        end
        ntries += 1
    end

    return peer_ids

end

function launch_processes_local(cluster_features, _::Type{<:PeerWorkers}, ips)

    nw = length(ips)
    
    peer_ids = nothing
    ntries = 1
    successfull = false
    while !successfull
        try
            peer_ids = addprocs(nw)
            successfull = true
            @info "peers deployed locally ... $ntries attempts"
        catch e
            report_exception(e)
            @info "error - peers deploy locally -- try $ntries"
            ntries > 10 && throw(e)
        end
        ntries += 1
    end

    return peer_ids
    
end

function launch_processes_mpi(cluster_features, _::Type{<:PeerWorkersMPI}, ips)

    nw = get(cluster_features, :node_count, 1)
    ppw =  get(cluster_features, :node_process_count, 1)
    np = nw * ppw;
 
    cluster_provider = cluster_features[:node_provider]

    exeflags = get(cluster_features, :exeflags, default_exeflags(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))
    exename = get(cluster_features, :exename, default_exename(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))
    directory = get(cluster_features, :directory, default_directory(cluster_provider))     
    threadlevel = get(cluster_features, :threadlevel, default_threadlevel(cluster_provider)) 
    mpiflags = get(cluster_features, :mpiflags, default_mpiflags(cluster_provider)) |> x -> Cmd(convert(Vector{String}, split(x)))

    peer_ids = nothing
    successfull = false
    ntries = 1
    while !successfull
        try
            peer_ids = addprocs(MPIWorkerManager(np); threadlevel=Symbol(threadlevel), mpiflags=mpiflags, dir=directory, exeflags=exeflags)
            successfull = true
            @info "MPI workers deployed locally ... $ntries attempts --- $mpiflags"
        catch e 
            report_exception(e)
            @info "error - MPI workers deploy locally -- try $ntries"
            ntries > 10 && throw(e)
        end
        ntries += 1
    end

    return peer_ids
    
end


function cluster_interrupt(cluster_handle)
    try
        check_cluster_handle(cluster_handle)
        cluster_features = cluster_deploy_info[cluster_handle][:features]
        node_provider = cluster_features[:node_provider]
        !can_interrupt(node_provider, cluster_handle) && error("cluster $cluster_handle cannot be interrupted") 
        cluster_type = cluster_features[:cluster_type]
        kill_processes(cluster_handle, cluster_type, cluster_features)
        interrupt_cluster(node_provider, cluster_handle)
        #@info "the cluster $cluster_handle has been interrupted"
    catch e
        println(e)
        return :fail
    end
    return :success
end

function cluster_resume(cluster_handle)
    try
        check_cluster_handle(cluster_handle)
        cluster_features = cluster_deploy_info[cluster_handle][:features]
        node_provider = cluster_features[:node_provider]
        !can_resume(node_provider, cluster_handle) && error("cluster $cluster_handle cannot be resumed") 
        ips = resume_cluster(node_provider, cluster_handle) 
        cluster_type = cluster_features[:cluster_type]

        pids = nothing
        try
            pids = launch_processes(node_provider, cluster_type, cluster_handle, ips)
        catch e 
            @warn "some error creating processes for cluster $cluster_handle ($e)"
        end

        if !isnothing(pids)
            cluster_deploy_info[cluster_handle][:pids] = pids
        else
            @error "resume partially failed due to an unrecoverable error in launching processes"
        end

        #@info "the cluster $cluster_handle has been resumed"
    catch e
        println(e)
        return :fail
    end
    return :success
end

terminated_cluster = Dict()

function cluster_terminate(cluster_handle)
    try    
        check_cluster_handle(cluster_handle)
        cluster_features = cluster_deploy_info[cluster_handle][:features]
        node_provider = cluster_features[:node_provider]
        cluster_isrunning(node_provider, cluster_handle) && kill_processes(cluster_handle, cluster_features[:cluster_type], cluster_features)
        terminate_cluster(node_provider, cluster_handle)
        terminated_cluster[cluster_handle] = cluster_deploy_info[cluster_handle]
        delete!(cluster_deploy_info, cluster_handle)
        #@info "the cluster $cluster_handle has been terminated"
    catch e
        println(e)
        return :fail
    end
    return :success
end

function kill_processes(cluster_handle, _::Type{<:ManagerWorkers}, cluster_features)
    pids = cluster_deploy_info[cluster_handle][:pids]
    if !isempty(pids) 
        wids = remotecall_fetch(workers, pids[1], role=:master)
        remotecall_fetch(rmprocs, pids[1], wids)
        #@fetchfrom pids[1] rmprocs(workers(role=:master))
        rmprocs(pids)
    end
    empty!(cluster_deploy_info[cluster_handle][:pids])
    @info "pids $pids removed (manager)"
end

function kill_processes(cluster_handle, _::Type{<:PeerWorkers}, cluster_features)
    pids = cluster_deploy_info[cluster_handle][:pids]
    if !isempty(pids) 
        rmprocs(pids)
        empty!(cluster_deploy_info[cluster_handle][:pids])
    end
    @info "pids $pids removed (peers)"
end


function cluster_restart(cluster_handle::Symbol)
    try
        check_cluster_handle(cluster_handle)
        cluster_features = cluster_deploy_info[cluster_handle][:features]
        cluster_provider = cluster_features[:node_provider]
        !cluster_isrunning(cluster_provider, cluster_handle) && error("cluster is not running")
        cluster_type = cluster_features[:cluster_type]
        kill_processes(cluster_handle, cluster_type, cluster_features)
        ips = get_ips(cluster_provider, cluster_handle) 

        pids = launch_processes(cluster_provider, cluster_type, cluster_handle, ips)
        cluster_deploy_info[cluster_handle][:pids] = pids
    catch e
        println(e)
        return :fail
    end

    return :success
end

function check_cluster_handle(cluster_handle; reconnecting = false)
    is_contract(cluster_handle) && error("The symbol $cluster_handle is a contract handle. You must submit a cluster handle.")
    haskey(terminated_cluster, cluster_handle) && error("cluster $cluster_handle has been terminated")
    !reconnecting && !haskey(cluster_deploy_info, cluster_handle) && error("cluster $cluster_handle not found")
end

get_user(cluster_features) =  get(cluster_features, :user, defaults_dict[Provider][:user])

function cluster_reconnect(cluster_handle::Symbol)

    try
        check_cluster_handle(cluster_handle; reconnecting=true)

        cluster_info = load_cluster(cluster_handle)

        if !isempty(cluster_info)
            cluster_provider = cluster_info[:provider]
            cluster_features = cluster_info[:features]
            cluster_deploy_info[cluster_handle] = Dict(:pids => Vector{Int}(), :features => cluster_features)
            if cluster_isrunning(cluster_provider, cluster_handle) 
                ips = get_ips(cluster_provider, cluster_handle)
                cluster_type = cluster_features[:cluster_type]
                pids = nothing
                try
                    pids = launch_processes(cluster_provider, cluster_type, cluster_handle, ips)  
                catch e
                    @warn "exception caught when launching processes ($e) - fix the problem and try '@restart :$cluster_handle'"
                    @error "error launching processes"
                end   
            
                if !isnothing(pids) 
                    cluster_deploy_info[cluster_handle][:pids] = pids
                end
            else
                return :success
            end
        else
            @error "The cluster $cluster_handle is not active"
        end
    catch e
        println(e)
        return :fail
    end

    return :success

 end



function report_exception(e)
    if e isa CompositeException
        @info "reporting composite exception:"
        for ee in e.exceptions
            @error ee
            if ee isa TaskFailedException
                @info "reporting task failed exception:"
                @error ee.task.exception
            else
                @error ee
            end
        end
    else
        @error e
    end
end

function cluster_nodes(cluster_handle)
    check_cluster_handle(cluster_handle)
    cluster_deploy_info[cluster_handle][:pids]
end

load_cluster(cluster_handle::Symbol; from = DateTime(0), cluster_type = :AnyCluster) = load_cluster(string(cluster_handle); from=from, cluster_type=cluster_type)

function load_cluster(cluster_handle::String; from = DateTime(0), cluster_type = :AnyCluster)
    result = Dict()
    try
        configpath = get(ENV,"CLOUD_CLUSTERS_CONFIG", pwd())
        cluster_file = occursin(r"\s*.cluster", cluster_handle) ? cluster_handle : cluster_handle * ".cluster"
        cluster_path = joinpath(configpath, cluster_file)
        contents = TOML.parsefile(cluster_path)
        timestamp = DateTime(contents["timestamp"])
        this_cluster_type = contents["type"]
        cluster_handle = Symbol(contents["name"])
        if timestamp > from && (cluster_type == :AnyCluster || cluster_type == Symbol(this_cluster_type))
            cluster_provider = contents["provider"]
            cluster_provider_type = fetchtype(cluster_provider)
            this_cluster_type_type = fetchtype(this_cluster_type)
            cluster_features = cluster_load(cluster_provider_type, this_cluster_type_type, cluster_handle, contents)
            if !isnothing(cluster_features)
                @info "$this_cluster_type $cluster_handle, created at $timestamp on $cluster_provider"
                result[:handle] = cluster_handle
                result[:provider] = cluster_provider_type
                result[:type] = this_cluster_type_type
                result[:timestamp] = timestamp
                result[:features] = cluster_features
            else
                @warn "$this_cluster_type cluster $cluster_handle is not active"
            end
        end
    catch e
        @error e
        @error "cluster $cluster_handle not found"
    end
    return result
end

function cluster_features(cluster_handle)
    Dict(cluster_deploy_info[cluster_handle][:features])
end