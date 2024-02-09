























#= features: a dictionary of cluster characteristics 
=#

struct ClusterHandle
end

abstract type ClusterType end

cluster_info = Dict()

function create_cluster(cluster_type::Type{<:ClusterType}, features)

    cluster_handle = ClusterHandle()

    cluster_info[cluster_handle] = (cluster_type, features)

    return cluster_handle

end


function forget_cluster(cluster_handle)
    delete!(cluster_info, cluster_handle)
end