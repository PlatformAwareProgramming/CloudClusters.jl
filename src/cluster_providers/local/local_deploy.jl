
local_cluster_info = Dict()

# 1. creates a worker process in the master node
# 2. from the master node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(type::Type{Localhost}, mode::Type{LinkMode}, features)
    
end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(type::Type{Localhost}, mode::Type{ClusterizeMode}, features)

end


# 1. create a set of local processes forming a virtual cluster
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(_::Type{Localhost}, cluster_type,  _::Type{CreateMode}, cluster_handle, cluster_features, _)

    count = get(cluster_features, :cluster_nodes, 1)

    user_id = ENV["USER"]
    ips = build_ips(cluster_type, count) 

    local_cluster_info[cluster_handle] = (ips, user_id)

    return ips, user_id
end

function build_ips(_::Type{ManagerWorkers}, count)
    ips = Dict()
    ips[:master] = Dict(:public_ip => "127.0.0.1", :private_ip => "127.0.0.1")
    for i in 0:count-1
        ips[Symbol(string("worker", i))] = Dict(:public_ip => "127.0.0.1", :private_ip => "127.0.0.1")
    end
    return ips
end

function build_ips(_::Type{PeerWorkers}, count)
    ips = Dict()
    for i in 0:count-1
        ips[Symbol(string("peer", i))] = Dict(:public_ip => "127.0.0.1", :private_ip => "127.0.0.1")
    end
    return ips
end

function launch_processes(_::Type{Localhost}, cluster_features, cluster_type, ips, user_id)
    launch_processes_local(cluster_features, cluster_type, ips, user_id)
end

#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(type::Type{Localhost}, cluster_handle)
   # NOTHING TO DO 
end

#==== CONTINUE CLUSTER ====#

function resume_cluster(type::Type{Localhost}, cluster_handle)
    return local_cluster_info[cluster_handle]
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(type::Type{Localhost}, cluster_handle)
    delete!(local_cluster_info, cluster_handle) 
end