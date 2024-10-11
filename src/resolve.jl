cluster_contract_resolved = Dict()

function cluster_resolve(contract_handle)
    
    cluster_type, cluster_features = cluster_contract[contract_handle]

    cluster_resolve(cluster_type, cluster_features, contract_handle)
end

function cluster_resolve(_::Type{<:ManagerWorkers}, cluster_features, contract_handle)

    !haskey(cluster_features, :manager_features) && @warn ":manager_features not specified"
    !haskey(cluster_features, :worker_features) && @warn ":worker_features not specified"

    manager_features = Dict{Symbol,Any}(get(cluster_features, :manager_features, cluster_features))
    worker_features = Dict{Symbol,Any}(get(cluster_features, :worker_features, cluster_features))

    if haskey(cluster_features, :node_provider) 
       manager_features[:node_provider] = worker_features[:node_provider] = cluster_features[:node_provider]
    end

#    @info "MANAGER: $manager_features"
#    @info "WORKER: $manager_features"

    (instance_type_master, node_provider) = call_resolve(manager_features)
    (instance_type_worker, node_provider) = call_resolve(worker_features)

    manager_features[:node_provider] = worker_features[:node_provider] = cluster_features[:node_provider] = node_provider

    cluster_contract_resolved[contract_handle] = (instance_type_master, instance_type_worker)

    :master_instance_type => instance_type_master, :worker_instance_type => instance_type_worker
end

function cluster_resolve(_::Type{<:PeerWorkers}, cluster_features, contract_handle)
    
    (instance_type, node_provider) = call_resolve(cluster_features)

    cluster_features[:node_provider] = node_provider

    cluster_contract_resolved[contract_handle] = instance_type

    :instance_type => instance_type
end

is_resolved(contract_handle) = haskey(cluster_contract_resolved, contract_handle)

set_unresolved!(contract_handle) = delete!(cluster_contract_resolved, contract_handle)

function call_resolve(features)

    resolve_args = Vector()
    for par in instance_features_order
        if haskey(features, par)
           push!(resolve_args, features[par] #=getfield(@__MODULE__, features[par])=#)
        else
           push!(resolve_args, instance_features[par] #=getfield(@__MODULE__, instance_features[par])=#)
        end
    end

    str = resolve(resolve_args...)
    return str
end

#function resolve(provider::Type{<:EC2Cluster}, node_machinetype, node_memory_size, #=node_ecu_count,=# node_vcpus_count, accelerator_count, accelerator_type, accelerator_arch, accelerator, processor, processor_arch, storage_type, storage_size, interconnection_bandwidth)
#        @warn provider, node_machinetype, node_memory_size, #=node_ecu_count, =# node_vcpus_count, accelerator_count, accelerator_type, accelerator_arch, accelerator, processor, processor_arch, storage_type, storage_size, interconnection_bandwidth
#        return node_machinetype
#end

instance_type_table = Dict{String, Any}()

function select_instances(filter...)

    result = Dict{String, Any}()

    for cond in filter
        if !haskey(instance_features, cond.first) 
           @warn "Only instance features are allowed. Ignoring $(cond.first)."
        end
    end

    for (instance_type, instance_feature) in instance_type_table
        select_flag = true
        for cond in filter
            if haskey(instance_features, cond.first)
               select_flag = select_flag && isa(cond.second, instance_feature[cond.first])
            end
        end

        if select_flag
           result[instance_type] = instance_feature
        end
    end

    return result

end

function fetch_features(instance_info; keytype = Symbol)

    parameters = Vector()
    instance_feature_table = Dict{Symbol, Any}()
    push!(parameters, :resolve)
    for name in instance_features_order

        name_key = keytype == String ? string(name) : name
        par = get(instance_info, name_key, instance_features[name])        

        ft = par isa Type ? par : PlatformAware.getFeature(name, par, instance_features, instance_features_type)
        
        push!(parameters, :($name::Type{>:$ft}))

        par_type = Type{>:ft}
        instance_feature_table[name] = par_type

    end

    return parameters, instance_feature_table
end
