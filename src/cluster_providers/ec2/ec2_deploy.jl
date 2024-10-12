
ec2_cluster_info = Dict()

function extract_mwfeature(cluster_features, type, featureid)
  if haskey(cluster_features, :manager_features) &&
    haskey(cluster_features, :worker_features) &&
    haskey(cluster_features[:manager_features], featureid) &&
    haskey(cluster_features[:worker_features], featureid) &&
   !haskey(cluster_features, featureid) 
    feature_master = cluster_features[:manager_features][featureid]     
    feature_worker = cluster_features[:worker_features][featureid]     
  elseif haskey(cluster_features, featureid) 
    feature_master = feature_worker = cluster_features[featureid]     
  else
    feature_master = feature_worker = defaults_dict[type][featureid]    
  end
  return feature_master, feature_worker
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

    count = get(cluster_features, :node_count, 1)
    user = get(cluster_features, :user, defaults_dict[CloudProvider][:user])

    imageid_master, imageid_worker = extract_mwfeature(cluster_features, AmazonEC2, :imageid)
    keyname_master, keyname_worker = extract_mwfeature(cluster_features, CloudProvider, :keyname)

    subnet_id = get(cluster_features, :subnet_id, get(defaults_dict[AmazonEC2], :subnet_id, nothing))
    placement_group = get(cluster_features, :placement_group, get(defaults_dict[AmazonEC2], :placement_group, nothing))  
    security_group_id = get(cluster_features, :security_group_id, get(defaults_dict[AmazonEC2], :security_group_id, nothing)) 

    auto_pg, placement_group = placement_group == "automatic" ? (true, ec2_create_placement_group(string("pgroup_", cluster_handle))) : (false, placement_group)
    auto_sg, security_group_id = security_group_id == "automatic" ? (true, ec2_create_security_group(string("sgroup_", cluster_handle), "")) : (false, security_group_id)

    cluster = ManagerWorkersCluster(AmazonEC2, string(cluster_handle), instance_type_master, instance_type_worker, count, 
                                         keyname_master, keyname_worker, imageid_master, imageid_worker, 
                                         subnet_id, placement_group, auto_pg, security_group_id, auto_sg,
                                         nothing, nothing, false, cluster_features)
    
    ec2_create_cluster(cluster)

    ec2_cluster_info[cluster_handle] = cluster

    cluster_save(AmazonEC2, cluster) 

    ips = get_ips(AmazonEC2, cluster)  

    @info "ips : $ips"
    
    return ips, user
end

#get_cluster(cluster_handle) = ec2_cluster_info[cluster_handle] |> first


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

    count = get(cluster_features, :node_count, 1)
    user = get(cluster_features, :user, defaults_dict[CloudProvider][:user]) 
    keyname = get(cluster_features, :keyname, defaults_dict[CloudProvider][:keyname])
    imageid = get(cluster_features, :imageid, defaults_dict[AmazonEC2][:imageid]) 
    subnet_id = get(cluster_features, :subnet_id, get(defaults_dict[AmazonEC2], :subnet_id, nothing))
    placement_group = get(cluster_features, :placement_group, get(defaults_dict[AmazonEC2], :placement_group, nothing))  
    security_group_id = get(cluster_features, :security_group_id, get(defaults_dict[AmazonEC2], :security_group_id, nothing)) 

    auto_pg, placement_group = placement_group == "automatic" ? (true, ec2_create_placement_group(string("pgroup_", cluster_handle))) : (false, placement_group)
    auto_sg, security_group_id = security_group_id == "automatic" ? (true, ec2_create_security_group(string("sgroup_", cluster_handle), "")) : (false, security_group_id)

    cluster = PeerWorkersCluster(AmazonEC2, string(cluster_handle), instance_type, count, 
                                 keyname, imageid, subnet_id, placement_group, auto_pg, security_group_id, auto_sg,
                                 nothing, nothing, false, cluster_features) 

    ec2_create_cluster(cluster)
 
    ec2_cluster_info[cluster_handle] = cluster

    cluster_save(AmazonEC2, cluster) 

    ips = get_ips(AmazonEC2, cluster) 

    return ips, user
end

function launch_processes(_::Type{AmazonEC2}, cluster_features, cluster_type, ips, user_id)
      launch_processes_ssh(cluster_features, cluster_type, ips, user_id)
end

get_ips(provider, cluster_handle::Symbol) = ec2_cluster_info[cluster_handle] |> h -> get_ips(provider, h)

#==== INTERRUPT CLUSTER ====#

can_interrupt(_::Type{AmazonEC2}, cluster_handle::Symbol) = ec2_cluster_info[cluster_handle] |> ec2_can_interrupt

function interrupt_cluster(_::Type{AmazonEC2}, cluster_handle)
  cluster = ec2_cluster_info[cluster_handle]
  interrupt_cluster(AmazonEC2, cluster)
end

#==== RESUME CLUSTER ====#

can_resume(_::Type{AmazonEC2}, cluster_handle::Symbol) = ec2_cluster_info[cluster_handle] |> ec2_can_resume

function resume_cluster(_::Type{AmazonEC2}, cluster_handle)
  cluster = ec2_cluster_info[cluster_handle]
  user = get(cluster.features, :user, defaults_dict[CloudProvider][:user])
  resume_cluster(AmazonEC2, cluster)    
  ips = get_ips(AmazonEC2, cluster) 
  return ips, user
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(provider::Type{AmazonEC2}, cluster_handle)
  cluster = ec2_cluster_info[cluster_handle]
  ec2_delete_cluster(cluster) 
  delete!(ec2_cluster_info, cluster_handle)
  forget_cluster(provider, cluster_handle)  
  nothing
end

#==== RESTART CLUSTER ====#

function reconnect_cluster(provider::Type{AmazonEC2}, cluster_handle, cluster)
  ec2_cluster_info[cluster_handle] = cluster
end

#=function get_user(_::Type{AmazonEC2}, cluster_handle::Symbol) 
  _, user = ec2_cluster_info[cluster_handle]
  return user
end=#
    
function forget_cluster(_::Type{AmazonEC2}, cluster_handle)
  configpath = get(ENV,"CLOUD_CLUSTERS_CONFIG", pwd())
  rm(joinpath(configpath, "$cluster_handle.cluster"))
end

cluster_isrunning(_::Type{AmazonEC2}, cluster_handle::Symbol) = ec2_cluster_info[cluster_handle] |> ec2_cluster_isrunning
cluster_isstopped(_::Type{AmazonEC2}, cluster_handle::Symbol) = ec2_cluster_info[cluster_handle] |> ec2_cluster_isstopped

function cluster_status(_::Type{AmazonEC2}, cluster_handle::Symbol, status_list)
  cluster = ec2_cluster_info[cluster_handle]
  cluster_status(AmazonEC2, cluster, status_list)
end