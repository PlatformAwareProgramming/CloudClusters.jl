



















abstract type EC2InstancesCluster <: ClusterType end
abstract type EC2InstancesClusterLink <: ClusterType end
abstract type EC2InstancesClusterNodes <: ClusterType end
abstract type EC2InstancesClusterCreate <: EC2InstancesCluster end


#=
Two modes:
 - link to existing cluster
 - link to existing set of EC2 instances
 - create a new cluster

=#
function deploy_cluster(type::Type{EC2InstancesCluster}, features)
    
    wid = if !haskey(features, :mode) 
              @error "Unkown mode" 
              -1
          elseif features[:mode] == :link_cluster
              deploy_cluster(EC2InstancesClusterLink, features)
          elseif features[:mode] == :link_nodes
              deploy_cluster(EC2InstancesClusterLink, features)
          elseif features[:mode] == :deploy_cluster
              deploy_cluster(EC2InstancesClusterCreate, features)
          else
              @error "Invalid cluster mode"
              -1
          end
end

# 1. creates a worker process in the master node
# 2. from the master node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(type::Type{EC2InstancesClusterLink}, features)
    #= the necessary information to perform cluster operations (interrupt, continue, terminate) =#
    deploy_info = Dict(:cluster_type => type)

    cluster_deploy_info[wid] = deploy_info
end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(type::Type{EC2InstancesClusterNodes}, features)
    #= the necessary information to perform cluster operations (interrupt, continue, terminate) =#
    deploy_info = Dict(:cluster_type => type)

    cluster_deploy_info[wid] = deploy_info
end

# 1. create a set of EC2 instances using the EC2 API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(type::Type{EC2InstancesClusterCreate}, features)
    #= the necessary information to perform cluster operations (interrupt, continue, terminate) =#
    deploy_info = Dict(:cluster_type => type)

    cluster_deploy_info[wid] = deploy_info
end

#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(type::Type{EC2InstancesClusterLink}, features)
    
end

function interrupt_cluster(type::Type{EC2InstancesClusterNodes}, features)

end

function interrupt_cluster(type::Type{EC2InstancesClusterCreate}, features)

end

#==== CONTINUE CLUSTER ====#

function continue_cluster(type::Type{EC2InstancesClusterLink}, features)
    
end

function continue_cluster(type::Type{EC2InstancesClusterNodes}, features)

end

function continue_cluster(type::Type{EC2InstancesClusterCreate}, features)

end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(type::Type{EC2InstancesClusterLink}, features)
    
end

function terminate_cluster(type::Type{EC2InstancesClusterNodes}, features)

end

function terminate_cluster(type::Type{EC2InstancesClusterCreate}, features)

end

