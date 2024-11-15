
np = 4

cluster_contract_1 = @cluster cluster_type => PeerWorkers node_provider=>Localhost node_count=>np
@test !isnothing(cluster_contract_1) 
@test isa(cluster_contract_1, Symbol)

cluster_contract_2 = @cluster cluster_type => ManagerWorkers node_provider=>Localhost node_count=>np
@test !isnothing(cluster_contract_2) 
@test isa(cluster_contract_2, Symbol)

@test !is_resolved(cluster_contract_1)
@test !is_resolved(cluster_contract_2)

deploy_error = false
try
    @deploy cluster_contract_1
catch e
    global deploy_error = true
end
@test !deploy_error  # attempt to deploy a non resolved contract


@test @resolve(cluster_contract_1, cluster_contract_2) |> r -> all(map(x -> x == :success, r))
@test is_resolved(cluster_contract_1)
@test is_resolved(cluster_contract_2)
@test @resolve(cluster_contract_1) == :success
@test is_resolved(cluster_contract_1)
@test @resolve(cluster_contract_2) == :success
@test is_resolved(cluster_contract_2)

# deploy cluster and test node processes
cluster_instance_1 = @deploy cluster_contract_1
@test !isnothing(cluster_instance_1)
@test isa(cluster_instance_1, Symbol)
cluster_nodes(cluster_instance_1) |> length == np

# check cluster nodes after restarting
@test @restart(cluster_instance_1) == :success
cluster_nodes(cluster_instance_1) |> length == np

# deploy cluster and test node processes
cluster_instance_2 = @deploy cluster_contract_2
@test !isnothing(cluster_instance_2)
@test isa(cluster_instance_2, Symbol)
cluster_nodes(cluster_instance_2) |> length == 1
pid_manager = @nodes(cluster_instance_2) |> first
nw = @fetchfrom pid_manager workers(role=:master)
@test length(nw) == np

# check cluster nodes after restarting
@test @restart(cluster_instance_2) == :success
cluster_nodes(cluster_instance_2) |> length == 1
pid_manager = @nodes(cluster_instance_2) |> first
nw = @fetchfrom pid_manager workers(role=:master)
@test length(nw) == np

# interrrupt fails for local clusters
@test @interrupt(cluster_instance_1, cluster_instance_2) |> r -> all(map(x -> x == :fail, r))

# resume fails for local clusters
@test @resume(cluster_instance_1, cluster_instance_2) |> r -> all(map(x -> x == :fail, r))

# terminate the clusters
@test @terminate(cluster_instance_1, cluster_instance_2) |> r -> all(map(x -> x == :success, r))

# a new attempt to terminate will fail
@test @terminate(cluster_instance_1) == :fail
@test @terminate(cluster_instance_2) == :fail