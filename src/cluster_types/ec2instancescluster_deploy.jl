abstract type EC2Cluster <: ClusterType end
abstract type EC2ClusterLink <: EC2Cluster end
abstract type EC2ClusterNodes <: EC2Cluster end
abstract type EC2ClusterCreate <: EC2Cluster end


#=
Two modes:
 - link to existing cluster
 - link to existing set of EC2 instances
 - create a new cluster

=#
function deploy_cluster(type::Type{EC2Cluster}, features)
    
    wid = if !haskey(features, :mode) 
              @error "Unkown mode" 
              -1
          elseif features[:mode] == :link_cluster
              deploy_cluster(EC2ClusterLink, features)
          elseif features[:mode] == :cluster_nodes
              deploy_cluster(EC2ClusterLink, features)
          elseif features[:mode] == :create_cluster
              deploy_cluster(EC2ClusterCreate, features)
          else
              @error "Invalid cluster mode"
              -1
          end
    wid
end

# 1. creates a worker process in the master node
# 2. from the master node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(type::Type{EC2ClusterLink}, features)
    #= the necessary information to perform cluster operations (interrupt, continue, terminate) =#
    deploy_info = Dict(:cluster_type => type)

    cluster_deploy_info[wid] = deploy_info
end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(type::Type{EC2ClusterNodes}, features)
    #= the necessary information to perform cluster operations (interrupt, continue, terminate) =#
    deploy_info = Dict(:cluster_type => type)

    cluster_deploy_info[wid] = deploy_info
end

# 1. create a set of EC2 instances using the EC2 API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(type::Type{EC2ClusterCreate}, features)
    #= the necessary information to perform cluster operations (interrupt, continue, terminate) =#
    deploy_info = Dict(:cluster_type => type)

    cluster_deploy_info[wid] = deploy_info
end

#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(wid, type::Type{EC2Cluster})
    
end

#==== CONTINUE CLUSTER ====#

function continue_cluster(wid, type::Type{EC2Cluster})
    
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(wid, type::Type{EC2Cluster})
    
end

