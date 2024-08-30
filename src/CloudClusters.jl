module CloudClusters

using Distributed
using MPIClusterManagers
using PlatformAware
using Base.Threads

include("config/configs.jl")
include("features/features.jl")
include("utils.jl")
include("cluster.jl")
include("resolve.jl")
include("deploy.jl")
include("macros.jl")
include("cluster_providers/ec2/ec2_backend.jl")
include("cluster_providers/ec2/ec2_deploy.jl")
include("cluster_providers/ec2/ec2_resolve.jl")
include("cluster_providers/gcp/gcp_backend.jl")
include("cluster_providers/gcp/gcp_deploy.jl")
include("cluster_providers/gcp/gcp_resolve.jl")

function __init__()
       load!()
end

# Lifecycle
export cluster_create, @cluster,
       cluster_resolve, @resolve, is_resolved, 
       cluster_deploy, @deploy,
       cluster_interrupt, @interrupt,
       cluster_resume, @resume,
       cluster_terminate, @terminate

# Cluster types
export ManagerWorkers, PeerWorkers

# Feature types
export PlatformAware, select_instances, @select


end # end CloudCluster