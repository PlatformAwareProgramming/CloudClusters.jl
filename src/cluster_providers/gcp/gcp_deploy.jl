
gcp_cluster_info = Dict()

function get_ips(_::Type{GoogleCloud}, cluster_handle)
    return gcp_get_ips_instance(gcp_cluster_info[cluster_handle], cluster_handle)
end

# 1. creates a worker process in the master node
# 2. from the master node, create worker processes in the compute nodes with MPIClusterManager
function deploy_cluster(_::Type{GoogleCloud},
                    _::Type{<:ManagerWorkers},
                    cluster_handle,
                    features)
    cluster = GCPManagerWorkers(string(cluster_handle))

    gcp_create_cluster(cluster)

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
        gcp_create_cluster(cluster)
    catch e
        terminate_cluster(gcptype, cluster_handle)

        throw(e)
    end

    gcp_cluster_info[cluster_handle] = cluster

    return cluster
end

# 1. create a set of GCP instances using the GCP API
# 2. run deploy_cluster to clusterize them and link to them
function deploy_cluster(type::Type{GoogleCloud}, mode::Type{CreateMode}, features)

end

function launch_processes(_::Type{GoogleCloud}, cluster_type, cluster_handle, ips, user_id)

end

#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(_::Type{GoogleCloud}, cluster_handle)
    
end

#==== CONTINUE CLUSTER ====#

function resume_cluster(type::Type{GoogleCloud}, cluster_handle)
    
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(type::Type{GoogleCloud}, cluster_handle)
    
end

#cluster_isrunning(_::Type{GoogleCloud}, cluster_handle) = gcp_cluster_info[cluster_handle] |> gcp_cluster_isrunning