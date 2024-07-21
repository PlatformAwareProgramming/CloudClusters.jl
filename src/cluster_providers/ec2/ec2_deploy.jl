
ec2_cluster_info = Dict()

# 1. creates a worker process in the master node
# 2. from the master node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(type::Type{AmazonEC2}, _::Type{LinkMode}, features)
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(type::Type{AmazonEC2}, _::Type{ClusterizeMode}, features)
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

end

# 1. create a set of EC2 instances using the EC2 API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(_::Type{AmazonEC2}, 
                        cluster_type::Type{ManagerWorkers},  
                        _::Type{CreateMode}, 
                        cluster_handle,
                        cluster_features,
                        instance_type_master,
                        instance_type_worker)
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

    count = get(cluster_features, :cluster_nodes, 1)

    if haskey(cluster_features[:manager_features], :imageid) &&
       haskey(cluster_features[:worker_features], :imageid) &&
      !haskey(cluster_features, :imageid) 
       imageid_master = cluster_features[:manager_features][:imageid]     
       imageid_worker = cluster_features[:worker_features][:imageid]     
     elseif haskey(cluster_features, :imageid) 
       imageid_master = imageid_worker = cluster_features[:imageid]     
     else
       imageid_master = imageid_worker = defaults_dict[:imageid]    
     end
 
    if haskey(cluster_features[:manager_features], :user) &&
       haskey(cluster_features[:worker_features], :user) &&
      !haskey(cluster_features, :user) 
      user_master = cluster_features[:manager_features][:user]
      user_worker = cluster_features[:worker_features][:user]
    elseif haskey(cluster_features, :user) 
      user_master = user_worker = cluster_features[:user]     
    else
      user_master = user_worker = defaults_dict[:user]
    end

    if haskey(cluster_features[:manager_features], :keyname) &&
       haskey(cluster_features[:worker_features], :keyname) &&
      !haskey(cluster_features, :keyname) 
      keyname_master = cluster_features[:manager_features][:keyname]     
      keyname_worker = cluster_features[:worker_features][:keyname]     
    elseif haskey(cluster_features, :keyname) 
      keyname_master = keyname_worker = cluster_features[:keyname]     
    else
      keyname_master = keyname_worker = defaults_dict[:keyname]
    end

    subnet_id = get(cluster_features, :subnet_id, get(defaults_dict, :subnet_id, nothing))
    placement_group = get(cluster_features, :placement_group, get(defaults_dict, :placement_group, nothing))  
    security_group_id = get(cluster_features, :security_group_id, get(defaults_dict, :security_group_id, nothing)) 

    placement_group = placement_group == "automatic" ? create_placement_group(string("pgroup_", cluster_handle)) : placement_group
    security_group_id = security_group_id == "automatic" ? create_security_group(string("sgroup_", cluster_handle), "") : security_group_id

    cluster = ManagerWorkersCluster(string("cluster_", cluster_handle), instance_type_master, instance_type_worker, count, 
                                         keyname_master, keyname_worker, imageid_master, imageid_worker, 
                                         subnet_id, placement_group, security_group_id,
                                         nothing, nothing, false)
    
    create_cluster(cluster)

    ec2_cluster_info[cluster_handle] = cluster

    ips = get_ips(cluster) 

    @info "ips : $ips"
    
    return ips[:master], user_master, count
end



# 1. create a set of EC2 instances using the EC2 API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(_::Type{AmazonEC2}, 
                        cluster_type::Type{PeerWorkers},  
                        _::Type{CreateMode}, 
                        cluster_handle,
                        cluster_features,
                        instance_type
                       )
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

    @info "DEFAULTS $defaults_dict"

    count = get(cluster_features, :cluster_nodes, 1)
    imageid = get(cluster_features, :imageid, defaults_dict[:imageid]) 
    user = get(cluster_features, :user, defaults_dict[:user]) 
    keyname = get(cluster_features, :keyname, defaults_dict[:keyname])
    subnet_id = get(cluster_features, :subnet_id, get(defaults_dict, :subnet_id, nothing))
    placement_group = get(cluster_features, :placement_group, get(defaults_dict, :placement_group, nothing))  
    security_group_id = get(cluster_features, :security_group_id, get(defaults_dict, :security_group_id, nothing)) 

    placement_group = placement_group == "automatic" ? create_placement_group(string("pgroup_", cluster_handle)) : placement_group
    security_group_id = security_group_id == "automatic" ? create_security_group(string("sgroup_", cluster_handle), "") : security_group_id

    @info "count=$count"
    @info "imageid=$imageid"
    @info "keyname=$keyname"
    @info "subnet_id=$subnet_id"
    @info "placement_group=$placement_group"
    @info "security_group_id=$security_group_id"
    @info "instance_type=$instance_type"

    cluster = PeerWorkersCluster(string("cluster_", cluster_handle), instance_type, count, 
                                      keyname, imageid, subnet_id, placement_group, security_group_id,
                                      nothing, nothing, false)

    create_cluster(cluster)
 
    ec2_cluster_info[cluster_handle] = cluster

    ips = get_ips(cluster)

    return ips, user
end

#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(type::Type{AmazonEC2}, cluster_handle)
    
end

#==== CONTINUE CLUSTER ====#

function resume_cluster(type::Type{AmazonEC2}, cluster_handle)
    
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(type::Type{AmazonEC2}, cluster_handle)
  cluster = ec2_cluster_info[cluster_handle]
  delete_cluster(cluster)
end

