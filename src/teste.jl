using CloudClusters
my_cluster_1 = @cluster cluster_type => ManagerWorkers node_count=>1 manager.node_machinetype=>PlatformAware.EC2Type_T3_xLarge worker.node_machinetype=>PlatformAware.EC2Type_T3_Medium
@resolve my_cluster_1
my_cluster_1_deployed = @deploy my_cluster_1
@restart my_cluster_1_deployed
@interrupt my_cluster_1_deployed
@resume my_cluster_1_deployed
exit()
CLOUD_CLUSTERS_CONFIG=~/.clusters ~/.juliaup/bin/julia
using CloudClusters
@reconnect :tlXPszcDTewGuTe
@terminate :tlXPszcDTewGuTe


my_cluster_1 = @cluster cluster_type => PeerWorkersMPI cluster_nodes=>2 node_machinetype=>PlatformAware.EC2Type_T3_xLarge


@terminate my_cluster_1_deployed

using CUDA
using GeoStats	
using GeoIO
using GeoArtifacts	
using CoordRefSystems	
using CoDa	
using ExtremeStats	
using DrillHoles	
using ImageQuilting	
using StratiGraphics	
using TuringPatterns	

using Distributed
using MPIClusterManagers
using Reexport
using PlatformAware
using Dates
using TOML
