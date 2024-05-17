module CloudClusters

using Distributed
using MPIClusterManagers
using PlatformAware

include("config/configs.jl")
include("features/features.jl")
include("cluster.jl")
include("resolve.jl")
include("deploy.jl")
include("macros.jl")
include("awsbackend.jl")
include("cluster_providers/ec2/ec2_deploy.jl")
include("cluster_providers/ec2/ec2_resolve.jl")
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
export PlatformAware, select_instances_by_features


end # end CloudCluster