module CloudClusters

using Distributed
using MPIClusterManagers

include("features.jl")
include("cluster.jl")
include("resolve.jl")
include("deploy.jl")
include("macros.jl")
include("awsbackend.jl")
include("cluster_providers/ec2instancescluster_deploy.jl")

export cluster_create, 
       cluster_resolve, is_resolved, 
       cluster_deploy, 
       cluster_interrupt, 
       cluster_continue, 
       cluster_terminate


end # end CloudCluster