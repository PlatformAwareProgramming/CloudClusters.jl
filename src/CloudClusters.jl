module CloudClusters

include("cluster.jl")
include("deploy.jl")
include("resolve.jl")
include("macros.jl")
include("awsbackend.jl")

export create_cluster, delete_cluster, get_ips

end # end CloudCluster