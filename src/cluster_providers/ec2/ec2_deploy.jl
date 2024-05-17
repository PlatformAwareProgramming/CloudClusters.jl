
ec2_cluster_info = Dict()

# 1. creates a worker process in the master node
# 2. from the master node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(type::Type{EC2Cluster}, _::Type{LinkMode}, features)
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(type::Type{EC2Cluster}, _::Type{ClusterizeMode}, features)
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

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
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

    count = get(cluster_features, :cluster_nodes,1)

    if haskey(cluster_features[:manager_features], :imageid) &&
       haskey(cluster_features[:worker_features], :imageid) &&
      !haskey(cluster_features, :imageid) 
       imageid_master = cluster_features[:manager_features][:imageid]     
       imageid_worker = cluster_features[:worker_features][:imageid]     
     elseif haskey(cluster_features, :imageid) 
       imageid_master = imageid_worker = cluster_features[:imageid]     
     else
       imageid_master = imageid_worker = default_imageid()    
     end
 
    if haskey(cluster_features[:manager_features], :user) &&
       haskey(cluster_features[:worker_features], :user) &&
      !haskey(cluster_features, :user) 
      user_master = cluster_features[:manager_features][:user]
      user_worker = cluster_features[:worker_features][:user]
    elseif haskey(cluster_features, :user) 
      user_master = user_worker = cluster_features[:user]     
    else
      user_master = user_worker = default_user()
    end

    if haskey(cluster_features[:manager_features], :keyname) &&
       haskey(cluster_features[:worker_features], :keyname) &&
      !haskey(cluster_features, :keyname) 
      keyname_master = cluster_features[:manager_features][:keyname]     
      keyname_worker = cluster_features[:worker_features][:keyname]     
    elseif haskey(cluster_features, :keyname) 
      keyname_master = keyname_worker = cluster_features[:keyname]     
    else
      keyname_master = keyname_worker = default_keyname()
    end

    subnet_id = get(cluster_features, :subnet_id, default_subnet_id())
    placement_group = get(cluster_features, :placement_group, create_placement_group(cluster_handle))  
    security_group_id = get(cluster_features, :security_group_id, default_security_group_id()) 

    cluster = create_cluster(cluster_type, 
                             cluster_handle, 
                             instance_type_master, 
                             instance_type_worker,
                             count,
                             imageid_master, 
                             imageid_worker,
                             user_master,
                             user_worker,
                             keyname_master,
                             keyname_worker, 
                             subnet_id,
                             placement_group,
                             security_group_id)

    ec2_cluster_info[cluster_handle] = cluster

    ips = get_ips(cluster) 
    
    return ips[:master], user_master, keyname_master
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
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

    count = get(cluster_features, :cluster_nodes, 1)
    imageid = get(cluster_features, :imageid, default_imageid()) 
    user = get(cluster_features, :user, default_user()) 
    keyname = get(cluster_features, :keyname, default_keyname())
    subnet_id = get(cluster_features, :subnet_id, default_subnet_id())
    placement_group = get(cluster_features, :placement_group, create_placement_group(cluster_handle))  
    security_group_id = get(cluster_features, :security_group_id, default_security_group_id()) 

    cluster = create_cluster(cluster_type,
                             cluster_handle, 
                             instance_type,
                             count,
                             imageid, 
                             user,
                             keyname,
                             subnet_id,
                             placement_group,
                             security_group_id)
 
    ec2_cluster_info[cluster_handle] = cluster

    ips = get_ips(cluster)

    return ips[:peers], user, keyname
end

#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(wid, type::Type{EC2Cluster})
    
end

#==== CONTINUE CLUSTER ====#

function resume_cluster(wid, type::Type{EC2Cluster})
    
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(wid, type::Type{EC2Cluster})
    
end

