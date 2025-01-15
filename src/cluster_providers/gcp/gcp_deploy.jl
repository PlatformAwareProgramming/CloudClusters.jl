
gcp_cluster_info = Dict()

function get_ips(gcptype::Type{GoogleCloud}, cluster_handle)
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
end

# 1. creates a worker process in the master node
# 2. from the master node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(gcptype::Type{GoogleCloud},
                    _::Type{<:ManagerWorkers},
                    _::Type{<:CreateMode},
                    cluster_handle,
                    cluster_features,
                    instance_type)
    node_count = get(cluster_features, :node_count, 1)
    source_image_workers = get(cluster_features, :source_image, defaults_dict[GoogleCloud][:source_image]) 
    source_image_master = get(cluster_features, :source_image_master, defaults_dict[GoogleCloud][:source_image_master])
    zone = get(cluster_features, :zone, defaults_dict[GoogleCloud][:zone]) 
    project = defaults_dict[GoogleCloud][:project]
    instance_type_master = instance_type[1]
    instance_type_worker = instance_type[2]

    cluster = GCPManagerWorkers(string(cluster_handle), 
                            source_image_master, 
                            source_image_workers,
                            node_count, 
                            instance_type_master, 
                            instance_type_worker,
                            zone, 
                            project, 
                            nothing)
    try
        cluster = gcp_create_cluster(cluster)
    catch e
        terminate_cluster(gcptype, cluster_handle)

        throw(e)
    end

    gcp_cluster_info[cluster_handle] = cluster

    return cluster
end

# 1. run the script to clusterize the nodes
# 2. call deploy_cluster to link ...
function deploy_cluster(gcptype::Type{GoogleCloud}, 
                    _::Type{<:PeerWorkers},
                    _::Type{<:CreateMode},
                    cluster_handle,
                    cluster_features,
                    instance_type)

    node_count = get(cluster_features, :node_count, 1)
    source_image = get(cluster_features, :source_image, defaults_dict[GoogleCloud][:source_image]) 
    zone = get(cluster_features, :zone, defaults_dict[GoogleCloud][:zone]) 
    project = defaults_dict[GoogleCloud][:project]

    cluster = GCPPeerWorkers(string(cluster_handle), 
                            source_image, 
                            node_count, 
                            instance_type, 
                            zone, 
                            project, 
                            nothing)
    try
        cluster = gcp_create_cluster(cluster)
    catch e
        terminate_cluster(gcptype, cluster_handle)

        throw(e)
    end

    gcp_cluster_info[cluster_handle] = cluster

    return cluster
end

function launch_processes(_::Type{GoogleCloud}, cluster_type, cluster_handle, ips, user_id)
    cluster = gcp_cluster_info[cluster_handle]

    return launch_processes_ssh(cluster.features, cluster_type, ips)
end

function launch_processes(_::Type{GoogleCloud}, cluster_type, cluster_handle, ips::Vector{Dict})
    cluster = gcp_cluster_info[cluster_handle]

    return launch_processes_ssh(cluster.features, cluster_type, ips)
end

#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(_::Type{GoogleCloud}, cluster_handle)
    @warn "CALLED NOT IMPLEMENTED METHOD!"
end

#==== CONTINUE CLUSTER ====#

function resume_cluster(type::Type{GoogleCloud}, cluster_handle)
    @warn "CALLED NOT IMPLEMENTED METHOD!"
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(type::Type{GoogleCloud}, cluster_handle)
    cluster = gcp_cluster_info[cluster_handle]

    gcp_terminate_cluster(cluster)
end

function cluster_isrunning(_::Type{GoogleCloud}, cluster_handle)
    try
        return gcp_cluster_info[cluster_handle] |> gcp_cluster_isrunning
    catch e
        @warn "Erro ao verificar o status do cluster: ", e
        return false
    end
end
