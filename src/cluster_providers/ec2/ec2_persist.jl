#=
mutable struct ManagerWorkersCluster <: Cluster
    name::String
    instance_type_master::String
    instance_type_worker::String
    count::Int
    key_name_master::String
    key_name_worker::String
    image_id_master::String
    image_id_worker::String
    subnet_id::Union{String, Nothing}
    placement_group::Union{String, Nothing}
    auto_pg::Bool
    security_group_id::Union{String, Nothing}
    auto_sg::Bool
    environment::Union{SharedFSInfo, Nothing}
    cluster_nodes::Union{Dict{Symbol, String}, Nothing}
    shared_fs::Bool
end 
=#


function cluster_save(_::Type{AmazonEC2}, cluster::ManagerWorkersCluster)

    contents = Dict()

    contents["type"] = ManagerWorkers
    contents["timestamp"] = string(now())
    contents["provider"] = AmazonEC2

    contents["name"] = cluster.name
    contents["instance_type_master"] = cluster.instance_type_master
    contents["instance_type_worker"] = cluster.instance_type_worker
    contents["count"] = cluster.count
    contents["key_name_master"] = cluster.key_name_master
    contents["key_name_worker"] = cluster.key_name_worker
    contents["image_id_master"] = cluster.image_id_master
    contents["image_id_worker"] = cluster.image_id_worker
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

function cluster_save(_::Type{AmazonEC2}, cluster::PeerWorkersCluster)

    contents = Dict()

    contents["type"] = PeerWorkers
    contents["timestamp"] = string(now())
    contents["provider"] = AmazonEC2

    contents["name"] = cluster.name
    contents["instance_type"] = cluster.instance_type
    contents["count"] = cluster.count
    contents["key_name"] = cluster.key_name
    contents["image_id"] = cluster.image_id
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

    @info cluster.name

    configpath = get(ENV,"CLOUD_CLUSTERS_CONFIG", pwd())

    open(joinpath(configpath, string(cluster.name, ".cluster")), "w") do io
        TOML.print(io, contents) do x
            x isa DataType && return string(x)
            error("unhandled type $(typeof(x))")
        end
    end

end

function cluster_load(_::Type{AmazonEC2}, cluster_handle)

    contents = TOML.parsefile(string(cluster_handle,".cluster"))

    cluster_type = contents["type"] |> fetchtype
    timestamp = contents["timestamp"]

    r = cluster_load(AmazonEC2, cluster_type, cluster_handle, contents) 

    return r, timestamp
end


function cluster_load(_::Type{AmazonEC2}, _::Type{ManagerWorkers}, cluster_handle, contents)

    instance_type_master = contents["instance_type_master"]
    instance_type_worker = contents["instance_type_worker"]
    count =  contents["count"]
    key_name_master = contents["key_name_master"]
    key_name_worker = contents["key_name_worker"]
    image_id_master = contents["image_id_master"]
    image_id_worker = contents["image_id_worker"]
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
    cluster_features = contents["cluster_features"] |> adjusttypefeatures
    shared_fs = contents["shared_fs"]

    cluster = ManagerWorkersCluster(AmazonEC2, string(cluster_handle), instance_type_master, instance_type_worker, count, 
                                    key_name_master, key_name_worker, image_id_master, image_id_worker, 
                                    subnet_id, placement_group, auto_pg, security_group_id, auto_sg,
                                    environment, cluster_nodes, shared_fs, cluster_features)

    return cluster
end


function adjusttypefeatures(_cluster_features)
    cluster_features = Dict()
    for (id, vl0) in _cluster_features
        idsym = Symbol(id)
        vl1 = idsym in [:cluster_type, :node_machinetype, :provider, :node_provider] ? fetchtype(vl0) : vl0
        vl2 = idsym in [:worker_features, :manager_features] ? adjusttypefeatures(vl1) : vl1
        cluster_features[idsym] = vl2 
    end
    return cluster_features
end

function cluster_load(_::Type{AmazonEC2}, _::Type{PeerWorkers}, cluster_handle, contents)

    instance_type = contents["instance_type"]
    count =  contents["count"]
    key_name = contents["key_name"]
    image_id = contents["image_id"]
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
    cluster_features = contents["cluster_features"] |> adjusttypefeatures
    shared_fs = contents["shared_fs"]

    cluster = PeerWorkersCluster(AmazonEC2, string(cluster_handle), instance_type, count, 
                                    key_name, image_id, 
                                    subnet_id, placement_group, auto_pg, security_group_id, auto_sg,
                                    environment, cluster_nodes, shared_fs, cluster_features)

    return cluster
end