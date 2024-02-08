include("pcluster.jl")

cluster_name = configure_cluster("us-east-1", "ubuntu2204", "t2.micro", "subnet-a91a21f4", "pcluster", "t2micro", 4, 4)