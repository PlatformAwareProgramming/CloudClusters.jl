
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
                        _::Type{ManagerWorkers},  
                        _::Type{CreateMode}, 
                        cluster_handle,
                        cluster_features,
                        instance_type)
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

    instance_type_master, instance_type_worker = instance_type

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

    auto_pg, placement_group = placement_group == "automatic" ? (true, create_placement_group(string("pgroup_", cluster_handle))) : (false, placement_group)
    auto_sg, security_group_id = security_group_id == "automatic" ? (true, create_security_group(string("sgroup_", cluster_handle), "")) : (false, security_group_id)

    cluster = ManagerWorkersCluster(AmazonEC2, string(cluster_handle), instance_type_master, instance_type_worker, count, 
                                         keyname_master, keyname_worker, imageid_master, imageid_worker, 
                                         subnet_id, placement_group, auto_pg, security_group_id, auto_sg,
                                         nothing, nothing, false, cluster_features)
    
    create_cluster(cluster)

    ec2_cluster_info[cluster_handle] = (cluster, user_master)

    cluster_save(AmazonEC2, cluster) 

    ips = get_ips(AmazonEC2, cluster)  

    @info "ips : $ips"
    
    return ips, user_master
end



# 1. create a set of EC2 instances using the EC2 API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(_::Type{AmazonEC2}, 
                        _::Type{PeerWorkers},  
                        _::Type{CreateMode}, 
                        cluster_handle,
                        cluster_features,
                        instance_type
                       )
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

    count = get(cluster_features, :cluster_nodes, 1)
    imageid = get(cluster_features, :imageid, defaults_dict[:imageid]) 
    user = get(cluster_features, :user, defaults_dict[:user]) 
    keyname = get(cluster_features, :keyname, defaults_dict[:keyname])
    subnet_id = get(cluster_features, :subnet_id, get(defaults_dict, :subnet_id, nothing))
    placement_group = get(cluster_features, :placement_group, get(defaults_dict, :placement_group, nothing))  
    security_group_id = get(cluster_features, :security_group_id, get(defaults_dict, :security_group_id, nothing)) 

    auto_pg, placement_group = placement_group == "automatic" ? (true, create_placement_group(string("pgroup_", cluster_handle))) : (false, placement_group)
    auto_sg, security_group_id = security_group_id == "automatic" ? (true, create_security_group(string("sgroup_", cluster_handle), "")) : (false, security_group_id)

    cluster = PeerWorkersCluster(AmazonEC2, string(cluster_handle), instance_type, count, 
                                      keyname, imageid, subnet_id, placement_group, auto_pg, security_group_id, auto_sg,
                                      nothing, nothing, false, cluster_features) 

    create_cluster(cluster)
 
    ec2_cluster_info[cluster_handle] = (cluster, user)

    cluster_save(AmazonEC2, cluster) 

    ips = get_ips(AmazonEC2, cluster) 

    return ips, user
end

function launch_processes(_::Type{AmazonEC2}, cluster_features, cluster_type, ips, user_id)
      launch_processes_ssh(cluster_features, cluster_type, ips, user_id)
end

#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(type::Type{AmazonEC2}, cluster_handle)
  cluster, _ = ec2_cluster_info[cluster_handle]
  interrupt_cluster(cluster) # TODO: implement in the backend ! 
end

#==== RESUME CLUSTER ====#

function resume_cluster(type::Type{AmazonEC2}, cluster_handle)
  cluster, user = ec2_cluster_info[cluster_handle]
  resume_cluster(cluster)  # TODO: implement in the backend ! 
  ips = get_ips(AmazonEC2, cluster) 
  return ips, user
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(provider::Type{AmazonEC2}, cluster_handle)
  cluster, _ = ec2_cluster_info[cluster_handle]
  delete_cluster(cluster)
  delete!(ec2_cluster_info, cluster_handle)
  forget_cluster(provider, cluster_handle)
  nothing
end

function restart_cluster(provider::Type{AmazonEC2}, cluster_handle, cluster)
  user = get_user(provider, cluster)
  ec2_cluster_info[cluster_handle] = (cluster, user)
end

function get_user(_::Type{AmazonEC2}, cluster::ManagerWorkersCluster)
    if haskey(cluster.features[:manager_features], :user) &&
       haskey(cluster.features[:worker_features], :user) &&
      !haskey(cluster.features, :user) 
      return cluster.features[:manager_features][:user]
    elseif haskey(cluster.features, :user) 
      return cluster.features[:user]     
    else
      return defaults_dict[:user]
    end
end

function get_user(_::Type{AmazonEC2}, cluster::PeerWorkersCluster)
  get(cluster.features, :user, defaults_dict[:user]) 
end
    
function forget_cluster(_::Type{AmazonEC2}, cluster_handle)
  configpath = get(ENV,"CLOUD_CLUSTERS_CONFIG", pwd())
  rm(joinpath(configpath, "$cluster_handle.cluster"))
end