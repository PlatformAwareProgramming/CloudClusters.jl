
ec2_cluster_info = Dict()


# 1. create a set of EC2 instances using the EC2 API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(_::Type{AmazonEC2}, 
                        _::Type{<:ManagerWorkers},  
                        _::Type{CreateMode}, 
                        cluster_handle,
                        cluster_features,
                        instance_type)
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

    instance_type_master, instance_type_worker = instance_type

    count = get(cluster_features, :node_count, 1)

    imageid_master, imageid_worker = extract_mwfeature(cluster_features, AmazonEC2, :imageid)

    subnet_id = get(cluster_features, :subnet_id, get(defaults_dict[AmazonEC2], :subnet_id, nothing))
    placement_group = get(cluster_features, :placement_group, get(defaults_dict[AmazonEC2], :placement_group, nothing))  
    security_group_id = get(cluster_features, :security_group_id, get(defaults_dict[AmazonEC2], :security_group_id, nothing)) 

    auto_pg, placement_group = placement_group == "automatic" ? (true, ec2_create_placement_group(string("pgroup_", cluster_handle))) : (false, placement_group)
    auto_sg, security_group_id = security_group_id == "automatic" ? (true, ec2_create_security_group(string("sgroup_", cluster_handle), "")) : (false, security_group_id)

    cluster = EC2ManagerWorkers(string(cluster_handle), instance_type_master, instance_type_worker, count, 
                                    imageid_master, imageid_worker, 
                                    subnet_id, placement_group, auto_pg, security_group_id, auto_sg,
                                    nothing, nothing, false, cluster_features)
    
    ec2_create_cluster(cluster)

    ec2_cluster_info[cluster_handle] = cluster

    ec2_cluster_save(cluster) 

    return cluster
end


# 1. create a set of EC2 instances using the EC2 API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(_::Type{AmazonEC2}, 
                        cluster_type::Type{<:PeerWorkers},  
                        _::Type{CreateMode}, 
                        cluster_handle,
                        cluster_features,
                        instance_type
                       )
    #= the necessary information to perform cluster operations (interrupt, resume, terminate) =#

    count = get(cluster_features, :node_count, 1)
    imageid = get(cluster_features, :imageid, defaults_dict[AmazonEC2][:imageid]) 
    subnet_id = get(cluster_features, :subnet_id, get(defaults_dict[AmazonEC2], :subnet_id, nothing))
    placement_group = get(cluster_features, :placement_group, get(defaults_dict[AmazonEC2], :placement_group, nothing))  
    security_group_id = get(cluster_features, :security_group_id, get(defaults_dict[AmazonEC2], :security_group_id, nothing)) 

    auto_pg, placement_group = placement_group == "automatic" ? (true, ec2_create_placement_group(string("pgroup_", cluster_handle))) : (false, placement_group)
    auto_sg, security_group_id = security_group_id == "automatic" ? (true, ec2_create_security_group(string("sgroup_", cluster_handle), "")) : (false, security_group_id)

    cluster = ec2_build_clusterobj(cluster_type, string(cluster_handle), instance_type, count, imageid,
                                subnet_id, placement_group, auto_pg, security_group_id, auto_sg, cluster_features)

    ec2_create_cluster(cluster)
 
    ec2_cluster_info[cluster_handle] = cluster

    ec2_cluster_save(cluster) 

    return cluster
end

ec2_build_clusterobj(_::Type{<:PeerWorkers}, cluster_handle, instance_type, count, imageid, subnet_id, 
                                             placement_group, auto_pg, security_group_id, auto_sg, cluster_features) =  
                                                 EC2PeerWorkers(cluster_handle, instance_type, count, imageid,
                                                                subnet_id, placement_group, auto_pg, security_group_id, auto_sg,
                                                                nothing, nothing, false, cluster_features)

ec2_build_clusterobj(_::Type{<:PeerWorkersMPI}, cluster_handle, instance_type, count, imageid, subnet_id, 
                                                placement_group, auto_pg, security_group_id, auto_sg, cluster_features) =  
                                                  EC2PeerWorkersMPI(cluster_handle, instance_type, count, imageid,
                                                                    subnet_id, placement_group, auto_pg, security_group_id, auto_sg,
                                                                    nothing, nothing, false, cluster_features)

get_ips(_::Type{AmazonEC2}, cluster_handle) = ec2_cluster_info[cluster_handle] |> ec2_get_ips


function launch_processes(_::Type{AmazonEC2}, cluster_type::Type{<:Cluster}, cluster_handle, ips)
    cluster = ec2_cluster_info[cluster_handle]
    launch_processes_ssh(cluster.features, cluster_type, ips)
end

function launch_processes(_::Type{AmazonEC2}, cluster_type::Type{<:PeerWorkersMPI}, cluster_handle, ips)
    cluster = ec2_cluster_info[cluster_handle]
    launch_processes_mpi(cluster.features, cluster_type, ips)
end

#==== INTERRUPT CLUSTER ====#

can_interrupt(_::Type{AmazonEC2}, cluster_handle) = ec2_cluster_info[cluster_handle] |> ec2_can_interrupt

function interrupt_cluster(_::Type{AmazonEC2}, cluster_handle)
  cluster = ec2_cluster_info[cluster_handle]
  ec2_interrupt_cluster(cluster)
end

#==== RESUME CLUSTER ====#

can_resume(_::Type{AmazonEC2}, cluster_handle) = ec2_cluster_info[cluster_handle] |> ec2_can_resume

function resume_cluster(_::Type{AmazonEC2}, cluster_handle)
  cluster = ec2_cluster_info[cluster_handle]
  ec2_resume_cluster(cluster)    
  return ec2_get_ips(cluster)
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(_::Type{AmazonEC2}, cluster_handle)
  cluster = ec2_cluster_info[cluster_handle]
  ec2_terminate_cluster(cluster) 
  ec2_delete_cluster(cluster_handle)  
  delete!(ec2_cluster_info, cluster_handle)
  nothing
end

#==== RESTART CLUSTER ====#

cluster_isrunning(_::Type{AmazonEC2}, cluster_handle) = ec2_cluster_info[cluster_handle] |> ec2_cluster_isrunning
cluster_isstopped(_::Type{AmazonEC2}, cluster_handle) = ec2_cluster_info[cluster_handle] |> ec2_cluster_isstopped


