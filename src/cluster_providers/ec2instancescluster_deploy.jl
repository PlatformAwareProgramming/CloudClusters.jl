
ec2_cluster_info = Dict()

# 1. creates a worker process in the master node
# 2. from the master node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(type::Type{EC2Cluster}, _::Type{LinkMode}, features)
    #= the necessary information to perform cluster operations (interrupt, continue, terminate) =#

end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(type::Type{EC2Cluster}, _::Type{ClusterizeMode}, features)
    #= the necessary information to perform cluster operations (interrupt, continue, terminate) =#

end

# 1. create a set of EC2 instances using the EC2 API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(_::Type{EC2Cluster}, 
                        cluster_type::Type{ManagerWorkers},  
                        _::Type{CreateMode}, 
                        cluster_handle,
                        cluster_features,
                        instance_type_master,
                        instance_type_worker)
    #= the necessary information to perform cluster operations (interrupt, continue, terminate) =#

    count = get(cluster_features, :cluster_nodes,1)

    if haskey(cluster_features[:master_features], :image_id) &&
       haskey(cluster_features[:worker_features], :image_id) &&
      !haskey(cluster_features, :image_id) 
       image_id_master = cluster_features[:master_features][:image_id]     
       image_id_worker = cluster_features[:worker_features][:image_id]     
     elseif haskey(cluster_features, :image_id) 
       image_id_master = image_id_worker = cluster_features[:image_id]     
     else
       image_id_master = image_id_worker = default_image_id()    
     end
 
    if haskey(cluster_features[:master_features], :user) &&
       haskey(cluster_features[:worker_features], :user) &&
      !haskey(cluster_features, :user) 
      user_master = cluster_features[:master_features][:user]
      user_worker = cluster_features[:worker_features][:user]
    elseif haskey(cluster_features, :user) 
      user_master = user_worker = cluster_features[:user]     
    else
      user_master = user_worker = default_user()
    end

    if haskey(cluster_features[:master_features], :key_name) &&
       haskey(cluster_features[:worker_features], :key_name) &&
      !haskey(cluster_features, :key_name) 
      key_name_master = cluster_features[:master_features][:key_name]     
      key_name_worker = cluster_features[:worker_features][:key_name]     
    elseif haskey(cluster_features, :key_name) 
      key_name_master = key_name_worker = cluster_features[:key_name]     
    else
      key_name_master = key_name_worker = default_key_name()
    end

    subnet_id = get(cluster_features, :subnet_id, default_subnet_id())
    placement_group = get(cluster_features, :placement_group, create_placement_group(cluster_handle))  
    security_group_id = get(cluster_features, :security_group_id, default_security_group_id()) 

    cluster = create_cluster(cluster_type, 
                             cluster_handle, 
                             instance_type_master, 
                             instance_type_worker,
                             count,
                             image_id_master, 
                             image_id_worker,
                             user_master,
                             user_worker,
                             key_name_master,
                             key_name_worker, 
                             subnet_id,
                             placement_group,
                             security_group_id)

    ec2_cluster_info[cluster_handle] = cluster

    ips = get_ips(cluster) 
    
    return ips[:master], user_master, key_name_master
end



# 1. create a set of EC2 instances using the EC2 API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(_::Type{EC2Cluster}, 
                        cluster_type::Type{PeerWorkers},  
                        _::Type{CreateMode}, 
                        cluster_handle,
                        cluster_features,
                        instance_type
                       )
    #= the necessary information to perform cluster operations (interrupt, continue, terminate) =#

    count = get(cluster_features, :cluster_nodes,1)
    image_id = get(cluster_features, :image_id, default_image_id()) 
    user = get(cluster_features, :user, default_user()) 
    key_name = get(cluster_features, :key_name, default_key_name())
    subnet_id = get(cluster_features, :subnet_id, default_subnet_id())
    placement_group = get(cluster_features, :placement_group, create_placement_group(cluster_handle))  
    security_group_id = get(cluster_features, :security_group_id, default_security_group_id()) 

    cluster = create_cluster(cluster_type,
                             cluster_handle, 
                             instance_type,
                             count,
                             image_id, 
                             user,
                             key_name,
                             subnet_id,
                             placement_group,
                             security_group_id)
 
    ec2_cluster_info[cluster_handle] = cluster

    ips = get_ips(cluster)

    return ips[:peers], user, key_name
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

