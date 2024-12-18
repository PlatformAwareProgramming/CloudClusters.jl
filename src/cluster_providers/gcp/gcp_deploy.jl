
# 1. creates a worker process in the manager node
# 2. from the manager node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(type::Type{GoogleCloud}, mode::Type{LinkMode}, features)
    
end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(type::Type{GoogleCloud}, mode::Type{ClusterizeMode}, features)

end

# 1. create a set of GCP instances using the GCP API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(type::Type{GoogleCloud}, mode::Type{CreateMode}, features)

end

function launch_processes(_::Type{GoogleCloud}, cluster_type, cluster_handle, ips, user_id)

end

#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(_::Type{GoogleCloud}, cluster_handle)
    
end

#==== CONTINUE CLUSTER ====#

function resume_cluster(type::Type{GoogleCloud}, cluster_handle)
    
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(type::Type{GoogleCloud}, cluster_handle)
    
end