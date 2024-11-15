
function readFeatures(features)
    common_features = Vector()
    manager_features = Vector()
    worker_features = Vector()

    for f in features
        @assert f.head == :call
        @assert f.args[1] == :(=>)
        #if arg.args[2] == :cluster_type
        #    cluster_type = arg.args[3]
        #    push!(common_features, Expr(:call, :(=>), :(:cluster_type), cluster_type) #= :cluster_type => cluster_type=#)
        #elseif arg.args[2] == :node_provider
        #    cloud_provider = arg.args[3]
        #    push!(common_features, Expr(:call, :(=>), :(:node_provider), cloud_provider)   #=:node_provider => cloud_provider=#)
        #else
        if isa(f.args[2], Expr) 
            @assert f.args[2].head == :.
            which_node = f.args[2].args[1]
            @assert which_node in [:manager,:worker]
            feature_id = f.args[2].args[2]
            feature_value = f.args[3]
            if which_node == :manager
               push!(manager_features, Expr(:call, :(=>), feature_id, feature_value) #=feature_id => feature_value=#)
            elseif which_node == :worker
               push!(worker_features, Expr(:call, :(=>), feature_id, feature_value) #=feature_id => feature_value=#)
            end
        else
            feature_id = f.args[2]
            feature_value = f.args[3]
            push!(common_features, Expr(:call, :(=>), QuoteNode(feature_id), feature_value) #=feature_id => feature_value=#)
        end
    end

    !isempty(manager_features) && push!(common_features, Expr(:call, :(=>), :(:manager_features), Expr(:call, :Dict, manager_features...)))
    !isempty(worker_features) && push!(common_features, Expr(:call, :(=>), :(:worker_features), Expr(:call, :Dict, worker_features...)))

    return common_features
end



macro cluster(features...)

    common_features = readFeatures(features)
    
    cluster_create_call = Expr(:call, :cluster_create, common_features...)
    esc(cluster_create_call) 
end

macro resolve(contract_ids...)
    resolve_calls = Vector()
    for contract_id in contract_ids
        push!(resolve_calls, Expr(:call, :cluster_resolve, contract_id))
    end
    b = length(contract_ids) > 1 ? :vect : :block
    esc(Expr(b, resolve_calls...))
end

macro deploy(contract_id, features...)

    common_features = readFeatures(features)

    deploy_call = Expr(:call, :cluster_deploy, contract_id, common_features...)
    esc(deploy_call)
end

macro interrupt(cluster_handles...)
    interrupt_calls = Vector()
    for cluster_id in cluster_handles
        push!(interrupt_calls, Expr(:call, :cluster_interrupt, cluster_id))
    end
    b = length(cluster_handles) > 1 ? :vect : :block
    esc(Expr(b, interrupt_calls...))
end

macro resume(cluster_handles...)
    resume_calls = Vector()
    for cluster_id in cluster_handles
        push!(resume_calls, Expr(:call, :cluster_resume, cluster_id))
    end
    b = length(cluster_handles) > 1 ? :vect : :block
    esc(Expr(b, resume_calls...))
end

macro terminate(cluster_handles...)
    terminate_calls = Vector()
    for cluster_id in cluster_handles
        push!(terminate_calls, Expr(:call, :cluster_terminate, cluster_id))
    end
    b = length(cluster_handles) > 1 ? :vect : :block
    esc(Expr(b, terminate_calls...))
end

macro select(features...)
   
    common_features = Vector()

    for f in features
        @assert f.head == :call
        @assert f.args[1] == :(=>)
  
        feature_id = f.args[2]
        feature_value = f.args[3]

        push!(common_features, Expr(:call, :(=>), QuoteNode(feature_id), feature_value) #=feature_id => feature_value=#)
    end

    select_call = Expr(:call, :select_instances, common_features...)

    esc(select_call)
end

macro clusters(params...)

    kw_params = Vector()

    for p in params
        @assert p.head == :(=)

        param_k = p.args[1]
        param_v = p.args[2]

        push!(kw_params, Expr(:kw, param_k, param_v))
    end

    call = Expr(:call, :cluster_list, kw_params...)

    esc(call)
end

macro restart(cluster_handles...)
    restart_calls = Vector()
    for cluster_id in cluster_handles
        push!(restart_calls, Expr(:call, :cluster_restart, cluster_id))
    end
    b = length(cluster_handles) > 1 ? :vect : :block
    esc(Expr(b, restart_calls...))
end

macro reconnect(cluster_handles...)
    reconnect_calls = Vector()
    for cluster_id in cluster_handles
        push!(reconnect_calls, Expr(:call, :cluster_reconnect, cluster_id))
    end
    b = length(cluster_handles) > 1 ? :vect : :block
    esc(Expr(b, reconnect_calls...))
end

macro features(cluster_handle)
    call = Expr(:call, :cluster_features, cluster_handle)
    esc(call)
end

macro nodes(cluster_handle)
    call = Expr(:call, :cluster_nodes, cluster_handle)
    esc(call)
end

macro status(cluster_handle)
end
