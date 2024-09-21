
#= features: a dictionary of cluster characteristics 
=#


# CONTEXTUAL CONTRACT:
#  -- locale
#  -- number of nodes
#  -- instance type of compute nodes
#  -- instance type of master node
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
#  -- size of storage at master
#  -- storage type (EBS)


abstract type Cluster end
abstract type ManagerWorkers <: Cluster end   # 1 nó master (head node) e N nós de computação
abstract type PeerWorkers <: Cluster end      # sem distinção de nó master


cluster_contract = Dict()


#function cluster_create(cluster_type::Type{<:ClusterType}, cluster_features)
function cluster_create(args...)
    
    cluster_features = Dict{Symbol, Any}(args)

    cluster_type = cluster_features[:cluster_type]

    contract_handle = create_sym(15)

    cluster_contract[contract_handle] = (cluster_type, cluster_features)

    return contract_handle
end


function forget_cluster(contract_handle)
    delete!(cluster_contract, contract_handle) 
end


function cluster_list(;from = DateTime(0), cluster_type = :AnyCluster)

    @assert cluster_type in [:AnyCluster, :ManagerWorkers, :PeerWorkers]

    result = Dict()

    configpath = get(ENV,"CLOUD_CLUSTERS_CONFIG", pwd())

    path_contents = readdir(configpath; join = true)

    for cluster_file in path_contents
        if occursin(r"\s*.cluster", cluster_file)
            contents = TOML.parsefile(cluster_file)
            timestamp = DateTime(contents["timestamp"])
            this_cluster_type = contents["type"]
            cluster_handle = Symbol(contents["name"])
            if timestamp > from && (cluster_type == :AnyCluster || cluster_type == Symbol(this_cluster_type))
                cluster_provider = contents["provider"]
                cluster_provider_type = fetchtype(cluster_provider)
                this_cluster_type_type = fetchtype(this_cluster_type)
                cluster_info = cluster_load(cluster_provider_type, this_cluster_type_type, cluster_handle, contents)
                if cluster_isrunning(cluster_info) 
                   @info "$this_cluster_type $cluster_handle, created at $timestamp on $cluster_provider"
                   result[cluster_handle] = Dict(:timestamp => timestamp, :info => cluster_info)
                else
                    forget_cluster(cluster_provider_type, cluster_handle)
                end
            end
        end
    end

    return result
end

