include("awsbackend.jl")


cluster_name = "pargocad"

create_placement_group(cluster_name)
group_id = create_security_group(cluster_name, "Grupo Pargocad")

delete_placement_group(cluster_name)
delete_security_group(group_id)
