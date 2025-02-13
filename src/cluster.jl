
#= features: a dictionary of cluster characteristics 
=#


# CONTEXTUAL CONTRACT:
#  -- locale
#  -- number of nodes
#  -- instance type of compute nodes
#  -- instance type of manager node
#  -- processor type
#  -- processor architecture
#  -- number of vcpus per node
#  -- interconnection type
#  -- -- enhanced network
#  -- -- ipv6 support
#  -- -- placement group (nome, cluster, partition, spread)
#  -- number of accelerators per node
#  -- accelerator type
#  ---- ...
#  -- memory size 
#  -- size of storage per node
#  -- size of storage at manager
#  -- storage type (EBS)


abstract type Cluster end
abstract type ManagerWorkers <: Cluster end   # 1 nó manager (head node) e N nós de computação
abstract type PeerWorkers <: Cluster end      # sem distinção de nó manager
abstract type PeerWorkersMPI <: PeerWorkers end


cluster_contract = Dict()


#function cluster_create(cluster_type::Type{<:ClusterType}, cluster_features)
function cluster_create(args...)
    
    cluster_features = Dict{Symbol, Any}(args)

    # set default cluster type
    !haskey(cluster_features, :cluster_type) && (cluster_features[:cluster_type] = PeerWorkers)
    
    cluster_type  = cluster_features[:cluster_type]
    
    contract_handle = create_sym(15)

    cluster_contract[contract_handle] = (cluster_type, cluster_features)

    return contract_handle
end

is_contract(handle) = haskey(cluster_contract, handle)


#cluster_reconnect_cache = Dict()

function cluster_list(;from = DateTime(0), cluster_type = :AnyCluster)

    !(cluster_type in [:AnyCluster, :ManagerWorkers, :PeerWorkers, :PeerWorkersMPI]) && error("$cluster_type is not a valid cluster type.")

    result = Vector()

    configpath = get(ENV,"CLOUD_CLUSTERS_CONFIG", pwd())

    path_contents = readdir(configpath; join = true)

    for cluster_file in path_contents
        if file_extension(cluster_file) == "cluster"
            cluster_data = load_cluster(cluster_file; from=from, cluster_type=cluster_type)
            !isempty(cluster_data) && push!(result, cluster_data)
         end
    end

    return result
end

