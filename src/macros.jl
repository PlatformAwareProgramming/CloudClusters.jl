




macro cluster(args...)

    @info args

    common_features = Vector()
    manager_features = Vector()
    worker_features = Vector()

    for arg in args
        @assert arg.head == :call
        @assert arg.args[1] == :(=>)
        #if arg.args[2] == :cluster_type
        #    cluster_type = arg.args[3]
        #    push!(common_features, Expr(:call, :(=>), :(:cluster_type), cluster_type) #= :cluster_type => cluster_type=#)
        #elseif arg.args[2] == :node_provider
        #    cloud_provider = arg.args[3]
        #    push!(common_features, Expr(:call, :(=>), :(:node_provider), cloud_provider)   #=:node_provider => cloud_provider=#)
        #else
        if isa(arg.args[2], Expr) 
            @assert arg.args[2].head == :.
            which_node = arg.args[2].args[1]
            @assert which_node in [:manager,:worker]
            feature_id = arg.args[2].args[2]
            feature_value = arg.args[3]
            if which_node == :manager
               push!(manager_features, Expr(:call, :(=>), feature_id, feature_value) #=feature_id => feature_value=#)
            elseif which_node == :worker
               push!(worker_features, Expr(:call, :(=>), feature_id, feature_value) #=feature_id => feature_value=#)
            end
        else
            feature_id = arg.args[2]
            feature_value = arg.args[3]
            @info feature_id, feature_value
            push!(common_features, Expr(:call, :(=>), QuoteNode(feature_id), feature_value) #=feature_id => feature_value=#)
        end
    end

    push!(common_features, Expr(:call, :(=>), :(:manager_features), Expr(:vect, manager_features...)))
    push!(common_features, Expr(:call, :(=>), :(:worker_features), Expr(:vect, worker_features...)))
    
    cluster_create_call = Expr(:call, :cluster_create, common_features...)

    @info cluster_create_call

    esc(cluster_create_call) 
end

macro resolve(contract_id)
    resolve_call = Expr(:call, :cluster_resolve, contract_id)
    esc(resolve_call)
end

macro deploy(contract_id)
    deploy_call = Expr(:call, :cluster_deploy, contract_id)
    esc(deploy_call)
end

macro interrupt(cluster_id)
    interrupt_call = Expr(:call, :cluster_interrupt, cluster_id)
    esc(interrupt_call)
end

macro resume(cluster_id)
    resume_call = Expr(:call, :cluster_resume, cluster_id)
    esc(resume_call)
end

macro terminate(cluster_id)
    terminate_call = Expr(:call, :cluster_terminate, cluster_id)
    esc(terminate_call)
end
