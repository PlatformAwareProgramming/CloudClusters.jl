#include("../src/CloudClusters.jl")
using TOML

cluster_handle = String(:example)
cluster_file = occursin(r"\s*.cluster", cluster_handle) ? cluster_handle : cluster_handle * ".cluster"
println(cluster_file)
contents = TOML.parsefile(cluster_file)
println(contents)