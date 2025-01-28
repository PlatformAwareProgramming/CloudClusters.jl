

function ec2_cluster_save(cluster::ManagerWorkers)

    contents = Dict()

    contents["type"] = ManagerWorkers
    contents["timestamp"] = string(now())
    contents["provider"] = AmazonEC2

    contents["name"] = cluster.name
    contents["instance_type_manager"] = cluster.instance_type_manager
    contents["instance_type_worker"] = cluster.instance_type_worker
    contents["count"] = cluster.count
    contents["image_id_manager"] = cluster.image_id_manager
    contents["image_id_worker"] = cluster.image_id_worker
    contents["user_manager"] = cluster.user_manager
    contents["user_worker"] = cluster.user_worker
    !isnothing(cluster.subnet_id) && (contents["subnet_id"] = cluster.subnet_id)
    !isnothing(cluster.placement_group) && (contents["placement_group"] = cluster.placement_group)
    contents["auto_pg"] = cluster.auto_pg
    !isnothing(cluster.security_group_id) && (contents["security_group_id"] = cluster.security_group_id)
    contents["auto_sg"] = cluster.auto_sg
    !isnothing(cluster.placement_group) && (contents["environment"] = Dict("file_system_id" => cluster.environment.file_system_id, 
                                                                           "file_system_ip" => cluster.environment.file_system_ip))
    contents["shared_fs"] = cluster.shared_fs

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

function ec2_cluster_save(cluster::PeerWorkers)

    contents = Dict()

    contents["type"] = PeerWorkers
    contents["timestamp"] = string(now())
    contents["provider"] = AmazonEC2

    contents["name"] = cluster.name
    contents["instance_type"] = cluster.instance_type
    contents["count"] = cluster.count
    contents["image_id"] = cluster.image_id
    contents["user"] = cluster.user
    !isnothing(cluster.subnet_id) && (contents["subnet_id"] = cluster.subnet_id)
    !isnothing(cluster.placement_group) && (contents["placement_group"] = cluster.placement_group)
    contents["auto_pg"] = cluster.auto_pg
    !isnothing(cluster.security_group_id) && (contents["security_group_id"] = cluster.security_group_id)
    contents["auto_sg"] = cluster.auto_sg
    !isnothing(cluster.placement_group) && (contents["environment"] = Dict("file_system_id" => cluster.environment.file_system_id, 
                                                                           "file_system_ip" => cluster.environment.file_system_ip))
    contents["shared_fs"] = cluster.shared_fs
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


function cluster_load(_::Type{AmazonEC2}, _::Type{<:ManagerWorkers}, cluster_handle, contents)

    instance_type_manager = contents["instance_type_manager"]
    instance_type_worker = contents["instance_type_worker"]
    count =  contents["count"]
    image_id_manager = contents["image_id_manager"]
    image_id_worker = contents["image_id_worker"]
    user_manager = contents["user_manager"]
    user_worker = contents["user_worker"]
    subnet_id = haskey(contents, "subnet_id") ? contents["subnet_id"] : nothing
    placement_group = haskey(contents, "placement_group") ? contents["placement_group"] : nothing
    auto_pg = contents["auto_pg"]
    security_group_id = haskey(contents, "security_group_id") ? contents["security_group_id"] : nothing
    auto_sg =contents["auto_sg"]
    environment =  haskey(contents, "environment") ? contents["environment"] : nothing
    !isnothing(environment) && (environment = SharedFSInfo(environment["file_system_id"], environment["file_system_ip"]))
    _cluster_nodes = contents["cluster_nodes"]
    cluster_nodes = Dict()
    for (node_name, instance_id) in _cluster_nodes
        cluster_nodes[Symbol(node_name)] = instance_id
    end
    cluster_features = contents["cluster_features"] |> ec2_adjusttypefeatures
    shared_fs = contents["shared_fs"]

    cluster = EC2ManagerWorkers(string(cluster_handle), instance_type_manager, instance_type_worker, count, 
                                    image_id_manager, image_id_worker, user_manager, user_worker,
                                    subnet_id, placement_group, auto_pg, security_group_id, auto_sg,
                                    environment, cluster_nodes, shared_fs, cluster_features)

    if ec2_cluster_status(cluster, ["running", "stopped"])
        ec2_cluster_info[cluster_handle] = cluster
        return cluster.features
    else
        ec2_delete_cluster(cluster_handle)
        return nothing
    end
end


function ec2_adjusttypefeatures(_cluster_features)
    cluster_features = Dict()
    for (id, vl0) in _cluster_features
        idsym = Symbol(id)
        vl1 = idsym in [:cluster_type, :node_machinetype, :provider, :node_provider] ? fetchtype(vl0) : vl0
        vl2 = idsym in [:worker_features, :manager_features] ? ec2_adjusttypefeatures(vl1) : vl1
        cluster_features[idsym] = vl2 
    end
    return cluster_features
end

function cluster_load(_::Type{AmazonEC2}, _::Type{<:PeerWorkers}, cluster_handle, contents)

    instance_type = contents["instance_type"]
    count =  contents["count"]
    image_id = contents["image_id"]
    user = contents["user"]
    subnet_id = haskey(contents, "subnet_id") ? contents["subnet_id"] : nothing
    placement_group = haskey(contents, "placement_group") ? contents["placement_group"] : nothing
    auto_pg = contents["auto_pg"]
    security_group_id = haskey(contents, "security_group_id") ? contents["security_group_id"] : nothing
    auto_sg =contents["auto_sg"]
    environment =  haskey(contents, "environment") ? contents["environment"] : nothing
    !isnothing(environment) && (environment = SharedFSInfo(environment["file_system_id"], environment["file_system_ip"]))
    _cluster_nodes = contents["cluster_nodes"]
    cluster_nodes = Dict()
    for (node_name, instance_id) in _cluster_nodes
        cluster_nodes[Symbol(node_name)] = instance_id
    end
    cluster_features = contents["cluster_features"] |> ec2_adjusttypefeatures
    shared_fs = contents["shared_fs"]

    cluster = EC2PeerWorkers(string(cluster_handle), instance_type, count, 
                                    image_id, user,
                                    subnet_id, placement_group, auto_pg, security_group_id, auto_sg,
                                    environment, cluster_nodes, shared_fs, cluster_features)

    if ec2_cluster_status(cluster, ["running", "stopped"])
        ec2_cluster_info[cluster_handle] = cluster
        return cluster.features
    else
        ec2_delete_cluster(cluster_handle)
        return nothing
    end
end

function ec2_delete_cluster(cluster_handle)
    configpath = get(ENV,"CLOUD_CLUSTERS_CONFIG", pwd())
    rm(joinpath(configpath, "$cluster_handle.cluster"))
    ec2_remove_temp_files(cluster_handle)
end


