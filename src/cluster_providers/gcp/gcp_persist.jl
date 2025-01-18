

function gcp_cluster_save(cluster::ManagerWorkers)

    contents = Dict()

    contents["type"] = ManagerWorkers
    contents["timestamp"] = string(now())
    contents["provider"] = GoogleCloud

    contents["name"] = cluster.name
    contents["user_manager"] = cluster.user_manager
    contents["user_worker"] = cluster.user_worker
    contents["instance_type_manager"] = cluster.instance_type_manager
    contents["instance_type_worker"] = cluster.instance_type_worker
    contents["count"] = cluster.count
    contents["image_id_manager"] = cluster.image_id_manager
    contents["image_id_worker"] = cluster.image_id_worker
    contents["cluster_nodes"] = cluster.cluster_nodes
    contents["cluster_features"] = cluster.features
    contents["zone"] = cluster.zone
    contents["project"] = cluster.project

    configpath = get(ENV,"CLOUD_CLUSTERS_CONFIG", pwd())

    open(joinpath(configpath, string(cluster.name, ".cluster")), "w") do io
        TOML.print(io, contents) do x
            x isa DataType && return string(x)
            error("unhandled type $(typeof(x))")
        end
    end

end

function gcp_cluster_save(cluster::PeerWorkers)

    contents = Dict()

    contents["type"] = PeerWorkers
    contents["timestamp"] = string(now())
    contents["provider"] = GoogleCloud

    contents["name"] = cluster.name
    contents["user"] = cluster.user
    contents["instance_type"] = cluster.instance_type
    contents["count"] = cluster.count
    contents["image_id"] = cluster.image_id
    contents["zone"] = cluster.zone
    contents["project"] = cluster.project
    contents["cluster_nodes"] = cluster.cluster_nodes
    contents["cluster_features"] = cluster.features

    configpath = get(ENV,"CLOUD_CLUSTERS_CONFIG", pwd())

    open(joinpath(configpath, string(cluster.name, ".cluster")), "w") do io
        TOML.print(io, contents) do x
            x isa DataType && return string(x)
            error("unhandled type $(typeof(x))")
        end
    end

end


function cluster_load(_::Type{GoogleCloud}, _::Type{<:ManagerWorkers}, cluster_handle, contents)

    instance_type_manager = contents["instance_type_manager"]
    instance_type_worker = contents["instance_type_worker"]
    count =  contents["count"]
    image_id_manager = contents["image_id_manager"]
    image_id_worker = contents["image_id_worker"]
    user_manager = contents["user_manager"] 
    user_worker = contents["user_worker"] 
    zone = contents["zone"] 
    project = contents["project"] 

    _cluster_nodes = contents["cluster_nodes"]
    cluster_nodes = Dict()
    for (node_name, instance_id) in _cluster_nodes
        cluster_nodes[Symbol(node_name)] = instance_id
    end

    cluster_features = contents["cluster_features"] |> gcp_adjusttypefeatures

    cluster = GCPManagerWorkers(string(cluster_handle), image_id_manager, image_id_worker, count, 
                                    instance_type_manager, instance_type_worker, user_manager, user_worker,
                                    zone, project, cluster_nodes, cluster_features)

    if gcp_cluster_status(cluster, ["RUNNING", "TERMINATED"])
        gcp_cluster_info[cluster_handle] = cluster
        return cluster.features
    else
        gcp_delete_cluster(cluster_handle)
        return nothing
    end
end


function gcp_adjusttypefeatures(_cluster_features)
    cluster_features = Dict()
    for (id, vl0) in _cluster_features
        idsym = Symbol(id)
        vl1 = idsym in [:cluster_type, :node_machinetype, :provider, :node_provider] ? fetchtype(vl0) : vl0
        vl2 = idsym in [:worker_features, :manager_features] ? gcp_adjusttypefeatures(vl1) : vl1
        cluster_features[idsym] = vl2 
    end
    return cluster_features
end

function cluster_load(_::Type{GoogleCloud}, _::Type{<:PeerWorkers}, cluster_handle, contents)

    image_id = contents["image_id"]
    count =  contents["count"]
    instance_type = contents["instance_type"]
    user = contents["user"]
    zone = contents["zone"]
    project = contents["project"]

    _cluster_nodes = contents["cluster_nodes"]
    cluster_nodes = Dict()
    for (node_name, instance_id) in _cluster_nodes
        cluster_nodes[Symbol(node_name)] = instance_id
    end
    
    cluster_features = contents["cluster_features"] |> gcp_adjusttypefeatures

    cluster = GCPPeerWorkers(string(cluster_handle), image_id, count, instance_type, user, zone, project,                            
                                    cluster_nodes, cluster_features)

    if gcp_cluster_status(cluster, ["RUNNING", "TERMINATED"])
        gcp_cluster_info[cluster_handle] = cluster
        return cluster.features
    else
        gcp_delete_cluster(cluster_handle)
        return nothing
    end
end

function gcp_delete_cluster(cluster_handle)
    configpath = get(ENV,"CLOUD_CLUSTERS_CONFIG", pwd())
    rm(joinpath(configpath, "$cluster_handle.cluster"))
    gcp_remove_temp_files(cluster_handle)
end


