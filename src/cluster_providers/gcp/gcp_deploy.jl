abstract type GCPCluster <: ClusterProvider end


# 1. creates a worker process in the master node
# 2. from the master node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(type::Type{GCPCluster}, mode::Type{LinkMode}, features)
    
end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(type::Type{GCPCluster}, mode::Type{ClusterizeMode}, features)

end

# 1. create a set of GCP instances using the GCP API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(type::Type{GCPCluster}, mode::Type{CreateMode}, features)

end


#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(wid, type::Type{GCPCluster})
    
end

#==== CONTINUE CLUSTER ====#

function resume_cluster(wid, type::Type{GCPCluster})
    
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(wid, type::Type{GCPCluster})
    
end