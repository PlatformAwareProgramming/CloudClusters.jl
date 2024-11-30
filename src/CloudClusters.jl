module CloudClusters

using Distributed
using MPIClusterManagers
using Reexport
@reexport using PlatformAware
using Base.Threads
using Dates
using TOML
using AWS
using Random

include("config/configs.jl") 
include("features/features.jl")
include("utils.jl")
include("provider.jl")
include("cluster.jl")
include("resolve.jl")
include("deploy.jl")
include("macros.jl")
include("cluster_providers/local/local_configs.jl")
include("cluster_providers/local/local_resolve.jl")
include("cluster_providers/local/local_deploy.jl")

function __init__()
       load!()
end

# Lifecycle
export cluster_create, @cluster,
       cluster_resolve, @resolve, is_resolved, 
       cluster_deploy, @deploy,
       cluster_interrupt, @interrupt,
       cluster_resume, @resume,
       cluster_terminate, @terminate,
       cluster_list, @clusters,
       cluster_reconnect, @reconnect,
       cluster_restart, @restart,
       cluster_features, @features,
       cluster_nodes, @nodes,
       cluster_defaultconfig,
       cluster_providers,
       cluster_features

# Cluster types
export Cluster, ManagerWorkers, PeerWorkers, PeerWorkersMPI

# Feature types
export PlatformAware, select_instances, @select

export Localhost

export DeployMode, LinkMode, ClusterizeMode, CreateMode

end # end CloudCluster