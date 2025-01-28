
gcp_cluster_info = Dict()

#=function get_ips(gcptype::Type{GoogleCloud}, cluster_handle)
    ips = Vector{Dict}()
    cluster = gcp_cluster_info[cluster_handle]
    try
        for i in cluster.count
            name = lowercase(String(cluster_handle)) * string(i)
            push!(ips, gcp_get_ips_instance(cluster, name))
        end 
    catch err 
        terminate_cluster(gcptype, cluster_handle)

        throw(err)
    end

    return ips
end=#

get_ips(_::Type{GoogleCloud}, cluster_handle) = gcp_cluster_info[cluster_handle] |> gcp_get_ips


# 1. creates a worker process in the manager node
# 2. from the manager node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(gcptype::Type{GoogleCloud},
                    _::Type{<:ManagerWorkers},
                    _::Type{<:CreateMode},
                    cluster_handle,
                    cluster_features,
                    instance_type)
    node_count = get(cluster_features, :node_count, 1)

    imageid_manager, imageid_worker = extract_mwfeature(cluster_features, GoogleCloud, :imageid)
    user_manager, user_worker = extract_mwfeature(cluster_features, GoogleCloud, :user)

    #image_id_workers = get(cluster_features, :image_id, defaults_dict[GoogleCloud][:image_id]) 
    #image_id_manager = get(cluster_features, :image_id_manager, defaults_dict[GoogleCloud][:image_id_manager])
    zone = get(cluster_features, :zone, defaults_dict[GoogleCloud][:zone]) 
    project = defaults_dict[GoogleCloud][:project]
    instance_type_manager = instance_type[1]
    instance_type_worker = instance_type[2]

    cluster = GCPManagerWorkers(string(cluster_handle), 
                            imageid_manager, 
                            imageid_worker,
                            node_count, 
                            instance_type_manager, 
                            instance_type_worker,
                            user_manager,
                            user_worker,
                            zone, 
                            project, 
                            nothing,
                            cluster_features)
    
    gcp_create_cluster(cluster)
 
    gcp_cluster_info[cluster_handle] = cluster

    gcp_cluster_save(cluster) 

    return cluster
end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(gcptype::Type{GoogleCloud}, 
                    cluster_type::Type{<:PeerWorkers},
                    _::Type{<:CreateMode},
                    cluster_handle,
                    cluster_features,
                    instance_type)

    node_count = get(cluster_features, :node_count, 1)
    imageid = get(cluster_features, :imageid, defaults_dict[GoogleCloud][:imageid]) 
    user = get(cluster_features, :user, defaults_dict[GoogleCloud][:user]) 
    zone = get(cluster_features, :zone, defaults_dict[GoogleCloud][:zone]) 
    project = defaults_dict[GoogleCloud][:project]

    cluster = gcp_build_clusterobj(cluster_type, 
                                   string(cluster_handle), 
                                   imageid, 
                                   node_count, 
                                   instance_type, 
                                   user,
                                   zone, 
                                   project, 
                                   nothing,
                                   cluster_features)
    
    gcp_create_cluster(cluster)

    gcp_cluster_info[cluster_handle] = cluster

    gcp_cluster_save(cluster) 

    return cluster
end

gcp_build_clusterobj(_::Type{<:PeerWorkers}, name, image_id, count, instance_type, user, zone, project, cluster_nodes, features) =  
                                             GCPPeerWorkers(name, image_id, count, instance_type, user, zone, project, cluster_nodes, features)

gcp_build_clusterobj(_::Type{<:PeerWorkersMPI}, name, image_id, count, instance_type, user, zone, project, cluster_nodes, features) =  
                                                GCPPeerWorkersMPI(name, image_id, count, instance_type, user, zone, project, cluster_nodes, features)

function launch_processes(_::Type{GoogleCloud}, cluster_type::Type{<:Cluster}, cluster_handle, ips)
    cluster = gcp_cluster_info[cluster_handle]
    launch_processes_ssh(cluster.features, cluster_type, ips)
end

function launch_processes(_::Type{GoogleCloud}, cluster_type::Type{<:PeerWorkersMPI}, cluster_handle, ips)
    cluster = gcp_cluster_info[cluster_handle]
    launch_processes_mpi(cluster.features, cluster_type, ips)
end

#==== INTERRUPT CLUSTER ====#

can_interrupt(_::Type{GoogleCloud}, cluster_handle) = gcp_cluster_info[cluster_handle] |> gcp_can_interrupt

function interrupt_cluster(_::Type{GoogleCloud}, cluster_handle)
  cluster = gcp_cluster_info[cluster_handle]
  gcp_interrupt_cluster(cluster)
end

#==== CONTINUE CLUSTER ====#

can_resume(_::Type{GoogleCloud}, cluster_handle) = gcp_cluster_info[cluster_handle] |> gcp_can_resume

function resume_cluster(_::Type{GoogleCloud}, cluster_handle)
  cluster = gcp_cluster_info[cluster_handle]
  gcp_resume_cluster(cluster)    
  return gcp_get_ips(cluster)
end


#==== TERMINATE CLUSTER ====#

function terminate_cluster(type::Type{GoogleCloud}, cluster_handle)
    cluster = gcp_cluster_info[cluster_handle]
    gcp_terminate_cluster(cluster) 
    gcp_delete_cluster(cluster_handle)  
    delete!(gcp_cluster_info, cluster_handle)
    return  
end

function cluster_isrunning(_::Type{GoogleCloud}, cluster_handle)
    try
        return gcp_cluster_info[cluster_handle] |> gcp_cluster_isrunning
    catch e
        @warn "Erro ao verificar o status do cluster: ", e
        return false
    end
end