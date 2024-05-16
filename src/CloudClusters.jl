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

export cluster_create, 
       cluster_resolve, is_resolved, 
       cluster_deploy, 
       cluster_interrupt, 
       cluster_continue, 
       cluster_terminate


end # end CloudCluster