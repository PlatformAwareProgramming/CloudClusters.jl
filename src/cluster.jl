
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


abstract type ClusterType end
abstract type ManagerWorkers <: ClusterType end   # 1 nó master (head node) e N nós de computação
abstract type PeerWorkers <: ClusterType end      # sem distinção de nó master

cluster_contract = Dict()

function cluster_create(cluster_type::Type{<:ClusterType}, cluster_features, contract_handle)

    if haskey(cluster_contract, contract_handle)
        @error "a cluster contract with handle $contract_handle exists."
        return nothing
    end

    cluster_contract[contract_handle] = (cluster_type, cluster_features)

    return contract_handle
end


function forget_cluster(contract_handle)
    delete!(cluster_contract, contract_handle)
end

