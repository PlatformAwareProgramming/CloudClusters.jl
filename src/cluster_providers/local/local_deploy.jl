
local_cluster_info = Dict()

# 1. creates a worker process in the manager node
# 2. from the manager node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(type::Type{Localhost}, mode::Type{LinkMode}, features)
    
end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(type::Type{Localhost}, mode::Type{ClusterizeMode}, features)

end


# 1. create a set of local processes forming a virtual cluster
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(_::Type{Localhost}, cluster_type,  _::Type{CreateMode}, cluster_handle, cluster_features, _)

    count = get(cluster_features, :node_count, 1)

    ips = build_ips(cluster_type, count) 

    local_cluster_info[cluster_handle] = (cluster_type, cluster_features, ips)

    return nothing
end

function get_ips(_::Type{Localhost}, cluster_handle) 
    _, _, ips = local_cluster_info[cluster_handle]
    return ips
end

function build_ips(_::Type{<:ManagerWorkers}, count)
    ips = Dict()
    ips[:manager] = Dict(:public_ip => "127.0.0.1", :private_ip => "127.0.0.1")
    for i in 0:count-1
        ips[Symbol(string("worker", i))] = Dict(:public_ip => "127.0.0.1", :private_ip => "127.0.0.1")
    end
    return ips
end

function build_ips(_::Type{<:PeerWorkers}, count)
    ips = Dict()
    for i in 0:count-1
        ips[Symbol(string("peer", i))] = Dict(:public_ip => "127.0.0.1", :private_ip => "127.0.0.1")
    end
    return ips
end

function launch_processes(_::Type{Localhost}, cluster_type::Type{<:Cluster}, cluster_handle, ips)
    _, cluster_features, _ = local_cluster_info[cluster_handle]
    launch_processes_local(cluster_features, cluster_type, ips)
end

function launch_processes(_::Type{Localhost}, cluster_type::Type{<:PeerWorkersMPI}, cluster_handle, ips)
    _, cluster_features, _ = local_cluster_info[cluster_handle]
    launch_processes_mpi(cluster_features, cluster_type, ips)
end

#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(_::Type{Localhost}, cluster_handle)
   # NOTHING TO DO 
end

function can_interrupt(_::Type{Localhost}, cluster_handle)  
    @assert !haskey(ec2_cluster_info, cluster_handle)
    @warn "local clusters cannot be interrupted/resumed"
    false
end

#==== CONTINUE CLUSTER ====#

function resume_cluster(type::Type{Localhost}, cluster_handle)
    _, _, ips = local_cluster_info[cluster_handle]
    return ips
end

function can_resume(_::Type{Localhost}, cluster_handle) 
    @assert !haskey(local_cluster_info, cluster_handle)
    @warn "local clusters cannot be interrupted/resumed"
    false
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(type::Type{Localhost}, cluster_handle)
    delete!(local_cluster_info, cluster_handle) 
end

cluster_isrunning(_::Type{Localhost}, cluster_handle::Symbol) = true
cluster_isstopped(_::Type{Localhost}, cluster_handle::Symbol) = true
