abstract type GCPCluster <: ClusterType end
abstract type GCPClusterLink <: GCPCluster end
abstract type GCPClusterNodes <: GCPCluster end
abstract type GCPClusterCreate <: GCPCluster end


#=
Two modes:
 - link to existing cluster
 - link to existing set of GCP instances
 - create a new cluster

=#
function deploy_cluster(type::Type{GCPCluster}, features)
    
    wid = if !haskey(features, :mode) 
              @error "Unkown mode" 
              -1
          elseif features[:mode] == :link_cluster
              deploy_cluster(GCPClusterLink, features)
          elseif features[:mode] == :cluster_nodes
              deploy_cluster(GCPClusterLink, features)
          elseif features[:mode] == :create_cluster
              deploy_cluster(GCPClusterCreate, features)
          else
              @error "Invalid cluster mode"
              -1
          end
end

# 1. creates a worker process in the master node
# 2. from the master node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(type::Type{GCPClusterLink}, features)
    
end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(type::Type{GCPClusterNodes}, features)

end

# 1. create a set of GCP instances using the GCP API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(type::Type{GCPClusterCreate}, features)

end


#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(wid, type::Type{GCPCluster})
    
end

#==== CONTINUE CLUSTER ====#

function continue_cluster(wid, type::Type{GCPCluster})
    
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(wid, type::Type{GCPCluster})
    
end