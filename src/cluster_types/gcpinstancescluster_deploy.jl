



















abstract type GCPInstancesCluster <: ClusterType end
abstract type GCPInstancesClusterLink <: ClusterType end
abstract type GCPInstancesClusterNodes <: ClusterType end
abstract type GCPInstancesClusterCreate <: GCPInstancesCluster end


#=
Two modes:
 - link to existing cluster
 - link to existing set of GCP instances
 - create a new cluster

=#
function deploy_cluster(type::Type{GCPInstancesCluster}, features)
    
    wid = if !haskey(features, :mode) 
              @error "Unkown mode" 
              -1
          elseif features[:mode] == :link_cluster
              deploy_cluster(GCPInstancesClusterLink, features)
          elseif features[:mode] == :link_nodes
              deploy_cluster(GCPInstancesClusterLink, features)
          elseif features[:mode] == :deploy_cluster
              deploy_cluster(GCPInstancesClusterCreate, features)
          else
              @error "Invalid cluster mode"
              -1
          end
end

# 1. creates a worker process in the master node
# 2. from the master node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(type::Type{GCPInstancesClusterLink}, features)
    
end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(type::Type{GCPInstancesClusterNodes}, features)

end

# 1. create a set of GCP instances using the GCP API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(type::Type{GCPInstancesClusterCreate}, features)

end
