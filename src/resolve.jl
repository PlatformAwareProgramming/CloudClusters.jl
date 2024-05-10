cluster_contract_resolved = Dict()

function cluster_resolve(contract_handle)
    
    cluster_type, cluster_features = cluster_contract[contract_handle]

    cluster_resolve(cluster_type, cluster_features, contract_handle)
end

function cluster_resolve(_::Type{<:ManagerWorkers}, cluster_features, contract_handle)

    master_features = get(cluster_features, :master_features, cluster_features)
    worker_features = get(cluster_features, :worker_features, cluster_features)

    master_features[:provider] = worker_features[:provider] = cluster_features[:provider]

    instance_type_master = call_resolve(master_features)
    instance_type_worker = call_resolve(worker_features)
    
    cluster_contract_resolved[contract_handle] = (instance_type_master, instance_type_worker)

    :master_instance_type => instance_type_master, 
    :worker_instance_type => instance_type_worker
end

function cluster_resolve(_::Type{<:PeerWorkers}, cluster_features, contract_handle)

    instance_type = call_resolve(cluster_features)

    cluster_contract_resolved[contract_handle] = :instance_type

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
           push!(resolve_args,  instance_features[par] #=getfield(@__MODULE__, instance_features[par])=#)
        end
    end

    instance_type = @eval resolve($resolve_args...)

    return instance_type
end

function resolve(provider::Type{<:EC2Cluster}, instance_type, memory_size, compute_units, vcpus_unit, accelerator_count, accelerator_type, accelerator_arch, accelerator_model, processor_model, processor_arch, storage_type, interconnection_type)
        @warn provider, instance_type, memory_size , compute_units, vcpus_unit, accelerator_count, accelerator_type, accelerator_arch, accelerator_model, processor_model, processor_arch, storage_type, interconnection_type
        return instance_type
end
