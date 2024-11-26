module CloudClusters

using Distributed
using MPIClusterManagers
using Reexport
@reexport using PlatformAware
using Base.Threads
using Dates
using TOML

include("config/configs.jl") 
include("features/features.jl")
include("utils.jl")
include("cluster.jl")
include("resolve.jl")
include("deploy.jl")
include("macros.jl")
include("cluster_providers/ec2/ec2_configs.jl")
include("cluster_providers/ec2/ec2_backend.jl")
include("cluster_providers/ec2/ec2_persist.jl")
include("cluster_providers/ec2/ec2_resolve.jl")
include("cluster_providers/ec2/ec2_deploy.jl")
include("cluster_providers/gcp/gcp_configs.jl")
#include("cluster_providers/gcp/gcp_backend.jl")
include("cluster_providers/gcp/gcp_resolve.jl")
include("cluster_providers/gcp/gcp_deploy.jl")
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
export ManagerWorkers, PeerWorkers, PeerWorkersMPI, Localhost

# Feature types
export PlatformAware, select_instances, @select

end # end CloudCluster