# CloudClusters.jl

_A package for creating, using, and managing cloud-based clusters deployed at the infrastructure of IaaS providers._

> [!NOTE]
> Currently, _CloudClusters.jl_ only supports [EC2](https://aws.amazon.com/ec2/). Those interested can ask us about progress with other providers.
> Contributors are welcome.

## Target users

_CloudClusters.jl_ targets users of the Julia programming language who need on-demand access to cutting-edge computing resources offered by IaaS cloud providers to attend to high-performance computing (HPC) application requirements.
   
## Pre-requisites


### Cloud providers' credentials

Even though _CloudClusters.jl_ currently only supports AWS EC2, it plans to support multiple IaaS cloud providers in the future. 

_CloudClusters.jl_ assumes that the user has properly configured the environment with their credentials to access the services of each provider they intend to use. 

### The configuration file (_CCconfig.toml_)

Creating clusters with _CloudClusters.jl_ requires specifying a set of configuration parameters. By default, they are specified in a file named _CCconfig.toml_ that is searched in the following locations, in this order:
* a path pointed by the CLOUD_CLUSTERS_CONFIG environment variable, if it exists;
* the current path.
  
Default configuration parameters can be overridden in programs. 

A description of each configuration parameter and how programs can override their default values from _CCconfig.toml_ is presented in a further section. Click [here](https://github.com/PlatformAwareProgramming/CloudClusters.jl/edit/decarvalhojunior-fh-patch-1-README/README.md#configuration-parameters) to move to there.


# Tutorial

In what follows, we present a tutorial on how _CloudClusters.jl_ works, divided in two parts: _basic use_ and _advanced use_. 

The basic tutorial teaches the reader how to create and deploy computations on ___peer-workers___ clusters, comprising a set of homogeneous VM instances deployed in the infrastructure of an IaaS cloud provider. 

The advanced tutorial includes:
* [a deeper discussion about _cluster contracts_](https://github.com/PlatformAwareProgramming/CloudClusters.jl/edit/decarvalhojunior-fh-patch-1-README/README.md#working-with-cluster-contracts);
* [how to use MPI with ___peer-workers___ clusters](https://github.com/PlatformAwareProgramming/CloudClusters.jl/edit/decarvalhojunior-fh-patch-1-README/README.md#peer-workers-mpi-clusters);
* [how to create ___manager-workers___ clusters, a kind of cluster that comprises an access node and a set of homogenous compute nodes only accessible through the access node](https://github.com/PlatformAwareProgramming/CloudClusters.jl/edit/decarvalhojunior-fh-patch-1-README/README.md#manager-workers-clusters);
* [a description of configuration parameters and how programs can override the default values from the _CCconfig.toml_ file](https://github.com/PlatformAwareProgramming/CloudClusters.jl/edit/decarvalhojunior-fh-patch-1-README/README.md#configuration-parameters).

# Basic use 

In what follows, we teach how to create ___peer-workers___ clusters and deploy computations on them using _Distributed.jl_ primitives.

Remember that the AWS credentials must be properly configured in the environment where the Julia REPL session or program will execute. 

## How to create a cluster 

_CloudClusters.jl_ offers six primitives, as _macros_, to create and manage the lifecycle of a cluster. They are: __@cluster__, __@resolve__, __@deploy__, __@terminate__, __@interrupt__, and __@resume__. 

First, let's try a simple scenario where a user creates a cluster comprising four ___t3.xlarge___ virtual machines (VM) instances through the AWS EC2 services. In the simplest way to do this, the user applies the __@cluster__ macro to the number of nodes and instance type, as arguments. 

```julia
using CloudClusters
using PlatformAware

my_first_cluster_contract = @cluster  node_count => 4  node_machinetype => EC2Type_T3_xLarge

```

Using __@cluster__ does not instantiate the cluster yet. It creates a _cluster contract_ and returns a handle for it. For instance, in the example, the _contract handle_ is stored in the _my_first_cluster_contract_ variable, through which the user can create one or more clusters later. 

> [!NOTE]
> In _CloudClusters.jl_, a handle is a symbol comprising 15 randomly calculated lower- and upper-case alphabetic characters (e.g.,```:FXqElAnSeTEpQAm``` ). Since they are symbols, they are printable and may be used directly to refer to a cluster contract.

A cluster contract must be resolved before creating clusters using it. For that, the user needs to apply __@resolve__ to the contract handle, as below:

```julia
@resolve my_first_cluster_contract
```

The __@resolve__ macro triggers a resolution procedure to calculate which instance type offered by one of the supported IaaS providers satisfies the contract. For ```my_first_cluster_contract```, the response is explicitly specified in the contract, i.e., the ___t3.xlarge___ instance type, only offered by AWS EC2. For advanced contract specifications, where cluster contract resolution shows its power, the reader can read the section [Working with cluster contracts](https://github.com/PlatformAwareProgramming/CloudClusters.jl/blob/decarvalhojunior-fh-patch-1-README/README.md#working-with-cluster-contracts).

A cluster may be instantiated by using ___@deploy___:

```julia
my_first_cluster = @deploy my_first_cluster_contract
```

The __@deploy__ macro will create a 4-node cluster comprising ___t3.xlarge___ AWS EC2 instances, returning a cluster handle that is assigned to the ```my_first_cluster``` variable. 

After __@deploy__, a set of _worker processes_ is created, one at each cluster node, whose _pids_ may be inspected by applying the ___nodes___ function to the cluster handle. 

In the following code, the user fetches the _pids_ of the processes at the cluster nodes of the cluster referred to through ```my_first_cluster```.

```julia-repl
julia> nodes(my_first_cluster)
4-element Vector{Int64}
2
3
4
5
```

As shown in the example, the default number of worker processes per cluster node is 1. However, the user may create N worker processes per cluster node using the ```node_process_count => N``` parameter in the contract specification. For example, in the following contract, the number of worker processes per cluster node is set to 2:

```julia
@cluster  node_count => 4  node_process_count => 2  node_machinetype => EC2Type_T3_xLarge
```


## Running computations on the cluster

The user may execute parallel computations on the cluster using _Distributed.jl_ operations. In fact, the user can employ any parallel/distributed computing package in the Julia ecosystem to launch computations across a set of worker processes. For instance, the advanced tutorial will show how to use _MPI.jl_ integrated to _Distributed.jl_. 

The following code, adapted from [The ultimate guide to distributed computing in Julia](https://github.com/Arpeggeo/julia-distributed-computing#the-ultimate-guide-to-distributed-computing-in-julia), processes a set of CSV files in a data folder in parallel, using _pmap_, across the worker processes placed at the cluster nodes. The result of each file processing is saved locally, as a CSV file in a results folder.  

```julia
using Distributed

@everywhere nodes(my_first_cluster) begin
  # load dependencies
  using ProgressMeter
  using CSV

  # helper functions
  function process(infile, outfile)
    # read file from disk
    csv = CSV.File(infile)

    # perform calculations
    sleep(60)

    # save new file to disk
    CSV.write(outfile, csv)
  end
end

# MAIN SCRIPT
# -----------

# relevant directories
indir  = joinpath(@__DIR__,"data")
outdir = joinpath(@__DIR__,"results")

# files to process
infiles  = readdir(indir, join=true)
outfiles = joinpath.(outdir, basename.(infiles))
nfiles   = length(infiles)

status = @showprogress pmap(1:nfiles; pids=nodes(my_first_cluster)) do i
  try
    process(infiles[i], outfiles[i])
    true # success
  catch e
    false # failure
  end
end

```

## Multiple clusters

Users can create cluster contracts, as well as deploy clusters from each contract, as many times as they need. For example, the following code creates a second cluster contract, named ```my_second_cluster_contract```, asking for a cluster of eight VM instances equipped with exactly eight NVIDIA GPUs of Ada-Lovelace architecture and at least 512GB of memory per node. Then, it creates two clusters from the new contract. 

```julia

my_second_cluster_contract = @cluster(node_count => 8,   
                                      node_memory_size => @atleast(512G),
                                      accelerator_count => @just(8),
                                      accelerator_architecture => Ada)

@resolve my_second_cluster_contract

my_second_cluster = @deploy my_second_cluster_contract
my_third_cluster = @deploy my_second_cluster_contract
```

This is an advanced use of cluster contracts, asking for instance types that satisfy a set of assumptions specified in the contract through instance parameters. At the time this tutorial was written, the AWS EC2 instance type that satisfies these assumptions is ___g6.48xlarge___, equipped with eight NVIDIA L4 T4 Tensor Core GPUs and 768GB of memory.

Now, there are three available clusters. The _pids_ of the last two ones may be also inspected:

```julia-repl
julia> nodes(my_second_cluster)
8-element Vector{Int64}
6
7
8
9
10
11
12
13

julia> nodes(my_third_cluster)
8-element Vector{Int64}
14
15
16
17
18
19
20
21
```

The user may orchestrate the processing power of multiple clusters to execute computations of their interest, independent of their providers. This is _multicluster computation_. However, it is important to note that communication operations between processes placed at nodes of different clusters (inter-cluster communication), mainly when these clusters are deployed at different IaaS providers, must be used with care due to the high communication cost, only when necessary and overlapping communication and computation using asynchronous operations,. 

## Interrupting and resuming a cluster

A cluster may be interrupted through the ___@interrupt___ macro: 

```julia
@interrupt my_first_cluster
```
The effect of ___@interrupt___ is pausing/stopping the VM instances of the cluster nodes. 

An interrupted cluster can be brought back to the running state using the ___@resume___ macro:

```julia
@resume my_first_cluster
```
The resuming operation starts the VM instances and creates a fresh set of worker processes, with new _pids_.

> [!CAUTION]
> ___@interrupt___ does not preserve the state of undergoing computations in the cluster, since it kills the worker processes running at the cluster nodes. The interruption of a cluster may be used to avoid the cost of cloud resources that are not currently being used. The user is responsible for saving the state of undergoing computations in a cluster to be interrupted and reloading the state after resuming, if necessary. 

## Restarting processes

A user can restart the processes at the cluster nodes by using the ___@restart___ macro: 

```julia
@restart my_first_cluster
```

The restart procedure kills all the current processes at the cluster nodes, losing their current state, and creates new processes, with fresh _pids_. 

## Terminating a cluster

Finally, a cluster may be finished/terminated using the ___@terminate___ macro:

```julia
@terminate my_first_cluster
```

After terminating, the cloud resources associated with the cluster are released.

## How to reconnect to a non-terminated cluster

If a cluster was not terminated in a previous execution of a Julia program or REPL session, the user may reconnect it using the ___@reconnect___ macro. For example:

```julia
@reconnect :FXqElAnSeTEpQAm
```

In the above code, ```:FXqElAnSeTEpQAm``` is the handle of a cluster not terminated in a previous execution session. But how may the user discover the cluster handle of a non-terminated cluster? For example, after a system crash? For that, the user may call the ___@clusters___ macro, which returns a list of non-terminated clusters in previous sessions that are still alive and can be reconnected:

```julia
julia> @clusters
[ Info: PeerWorkers FXqElAnSeTEpQAm, created at 2024-10-08T09:12:40.847 on PlatformAware.AmazonEC2
1-element Vector{Any}:
 Dict{Any, Any}(:handle => :FXqElAnSeTEpQAm, :provider => PlatformAware.AmazonEC2, :type => PeerWorkers, :timestamp => Dates.DateTime("2024-10-08T09:12:40.847"))
```

## Advanced Use

### Working with cluster contracts 

As shown in the previous examples of using the ___@cluster___ macro, _CloudClusters.jl_ supports _cluster contracts_ to specify _assumptions_ about _features_ of clusters, with special attention to the types of VM instances comprising cluster nodes. 

Cluster contracts are a set of key-value pairs ```k => v``` called _assumption parameters_, where ```k``` is a name and ```v``` is a value or [_platform type_](). A predefined set of assumption parameters is supported, each with a _name_ and a default value or _base platform type_. 

The set of assumption parameters currently supported are listed [here](https://github.com/PlatformAwareProgramming/CloudClusters.jl/blob/decarvalhojunior-fh-patch-1-README/README.md#list-of-instance-feature-parameters), providing a wide spectrum of assumptions for allowing users to specify the architectural characteristics of a cluster to satisfy their needs. Note that assumption parameters are classified in cluster and instance parameters, where _instance parameters_ are the assumption parameters considered in the instance resolution procedure (_resolve_).

In the case of ```my_first_cluster_contract```, the user uses the assumption parameters ___node_count___ and ___nodes_machinetype___ to specify that the required cluster must have four nodes and that the VM instances that comprise the cluster nodes must be of the ___t3.xlarge___ type, offered by the AWS EC2 provider. This is a direct approach, the simplest and less abstract one, where the resolution procedure, triggered by a call to __@resolve__ , will return the EC2's ___t3.xlarge___ as the VM instance type that satisfies the contract.

On the other hand, ```my_second_cluster_contract``` employs an indirect approach, demonstrating the ability of the resolution procedure to find the VM instance type from a set of abstract assumptions. They are specified using the assumption parameters __accelerator_count__, __accelerator_architecture__, and __accelerator_memory__, asking for cluster nodes with eight GPUs of NVIDIA Ada Lovelace architecture and at least 512GB of memory. Under these assumptions, the call to ___@resolve___ returns the __g6.48xlarge__ instance type of AWS EC2.


#### List of assumption parameters

___Cluster parameters___ specify features of the cluster:
   * __cluster_type__::```Cluster```, denoting the cluster type: ManagerWorkers or PeerWorkers;
   * __node_count__::```Integer```, denoting the number of cluster nodes (default to _1_);
   * __node_process_count__::```Integer```, denoting the number of Julia processes (MPI ranks) per node (default to _1_).

___Instance parameters___, with their respective base platform types, are listed below:

   * __node_provider__::```CloudProvider```
   * __cluster_locale__::```Locale```
   * __node_machinetype__::```InstanceType```
   * __node_memory_size__::```@atleast 0```
   * __node_ecu_count__::```@atleast 1```
   * __node_vcpus_unit__::```@atleast 1```
   * __accelerator_count__::```@atleast 0```
   * __accelerator_memory__::```@atleast 0```
   * __accelerator_type__::```AcceleratorType```
   * __accelerator_arch__::```AcceleratorArchitecture```
   * __accelerator__::```AcceleratorModel```
   * __processor__::```ProcessorModel```
   * __processor_manufacturer__::```Manufacturer```
   * __processor_microarchitecture__::```ProcessorArchitecture```
   * __storage_type__::```StorageType```
   * __storage_size__::```@atleast 0```
   * __network_performance__::```@atleast 0```
      
#### Querying contracts

In the current implementation of _CloudClusters.jl_, since contract resolution, using ___@resolve___, is implemented on top of Julia's multiple dispatch mechanism, it does not support ambiguity, i.e., just a single VM instance type must satisfy the contract. Otherwise, ___resolve___ returns an ambiguity error, like in the example below:

```julia-repl
julia> cc = @cluster(node_count => 4, 
                     accelerator_count => @atleast(4),
                     accelerator_architecture => Ada, 
                     node_memory_size => @atleast(256G))
:NKPlCvagfSSpIgD

julia> @resolve cc
ERROR: MethodError: resolve(::Type{CloudProvider}, ::Type{MachineType}, ::Type{Tuple{AtLeast256G, AtMostInf, var"#92#X"} where var"#92#X"}, ::Type{Tuple{AtLeast1, AtMostInf, Q} where Q}, ::Type{Tuple{AtLeast4, AtMostInf, var"#91#X"} where var"#91#X"}, ::Type{AcceleratorType}, ::Type{Ada}, ::Type{Manufacturer}, ::Type{Tuple{AtLeast0, AtMostInf, Q} where Q}, ::Type{Accelerator}, ::Type{Processor}, ::Type{Manufacturer}, ::Type{ProcessorMicroarchitecture}, ::Type{StorageType}, ::Type{Tuple{AtLeast0, AtMostInf, Q} where Q}, ::Type{Tuple{AtLeast0, AtMostInf, Q} where Q}) is ambiguous.
```

The user can use the ___@select___ macro to query which instance types satisfy the ambiguous contract: 

```julia-repl
julia> @select(node_count => 4,
               accelerator_count => @atleast(4),
               accelerator_architecture => Ada, 
               node_memory_size => @atleast(256G))
┌ Warning: Only instance features are allowed. Ignoring node_count.
└ @ CloudClusters ~/Dropbox/Copy/ufc_mdcc_hpc/CloudClusters.jl/src/resolve.jl:78
Dict{String, Any} with 3 entries:
  "g6.48xlarge"    => Dict{Symbol, Any}(:processor => Type{>:AMDEPYC_7R13}, :accelerator_architecture => Type{>:Ada}, :processor_manufacturer => Type{>:AMD}, :storage_type => Type{>:StorageType_EC2_NVMeSSD}, :node_memory_size => Type{>:Tuple{AtLeast512G, AtMost1T, 8.24634e11}}, :storage_size => Type{>:Tuple{AtLeast32T, AtMost64T, 6.52835e13}}, :node_provider => Type{>:AmazonEC2}, :node_vcpus_count => Type{>:Tuple{AtLeast128, AtMost256, 192.0}}, :accelerator_count => Type{>:Tuple{AtLeast8, AtMost8, 8.0}}, :network_performance => Type{>:Tuple{AtLeast64G, AtMost128G, 1.07374e11}}, :accelerator => Type{>:NVIDIA_L4}, :accelerator_type => Type{>:GPU}, :accelerator_memory_size => Type{>:Tuple{AtLeast16G, AtMost32G, 2.57698e10}}, :accelerator_manufacturer => Type{>:NVIDIA}, :node_machinetype => Type{>:EC2Type_G6_48xLarge}, :processor_microarchitecture => Type{>:Zen})
  "g2-standard-96" => Dict{Symbol, Any}(:processor => Type{>:IntelXeon_8280L}, :accelerator_architecture => Type{>:Ada}, :processor_manufacturer => Type{>:Intel}, :storage_type => Type{>:StorageType}, :node_memory_size => Type{>:Tuple{AtLeast256G, AtMost512G, 4.12317e11}}, :storage_size => Type{>:Tuple{AtLeast0, AtMostInf, Q} where Q}, :node_provider => Type{>:GoogleCloud}, :node_vcpus_count => Type{>:Tuple{AtLeast64, AtMost128, 96.0}}, :accelerator_count => Type{>:Tuple{AtLeast8, AtMost8, 8.0}}, :network_performance => Type{>:Tuple{AtLeast64G, AtMost128G, 1.07374e11}}, :accelerator => Type{>:NVIDIA_L4}, :accelerator_type => Type{>:GPU}, :accelerator_memory_size => Type{>:Tuple{AtLeast16G, AtMost32G, 2.57698e10}}, :accelerator_manufacturer => Type{>:NVIDIA}, :node_machinetype => Type{>:GCPType_G2}, :processor_microarchitecture => Type{>:CascadeLake})
  "g6.24xlarge"    => Dict{Symbol, Any}(:processor => Type{>:AMDEPYC_7R13}, :accelerator_architecture => Type{>:Ada}, :processor_manufacturer => Type{>:AMD}, :storage_type => Type{>:StorageType_EC2_NVMeSSD}, :node_memory_size => Type{>:Tuple{AtLeast256G, AtMost512G, 4.12317e11}}, :storage_size => Type{>:Tuple{AtLeast8T, AtMost16T, 1.63209e13}}, :node_provider => Type{>:AmazonEC2}, :node_vcpus_count => Type{>:Tuple{AtLeast64, AtMost128, 96.0}}, :accelerator_count => Type{>:Tuple{AtLeast4, AtMost4, 4.0}}, :network_performance => Type{>:Tuple{AtLeast32G, AtMost64G, 5.36871e10}}, :accelerator => Type{>:NVIDIA_L4}, :accelerator_type => Type{>:GPU}, :accelerator_memory_size => Type{>:Tuple{AtLeast16G, AtMost32G, 2.57698e10}}, :accelerator_manufacturer => Type{>:NVIDIA}, :node_machinetype => Type{>:EC2Type_G6_24xLarge}, :processor_microarchitecture => Type{>:Zen})
```
Notice that ___@select___ emits a warning because __node_count__ is ignored since only instance features are considered in contract resolution.

Three VM instance types satisfy the contract, since they provide at least 256GB of memory and at least four NVIDIA GPUs of Ada architecture (L4 Tensor Core). They are: ___g6.48xlarge___, ___g2-standard-96___, and ___g6.24xlarge___. The user may inspect the features of each instance type and write a contract that selects one directly.

```julia-repl
julia> cc = @cluster  node_count => 4  node_machinetype => EC2Type_G6_48xLarge
:mBrvXUsilkpxWJC

julia> @resolve cc
1-element Vector{Pair{Symbol, SubString{String}}}:
 :instance_type => "g6.48xlarge"
```

### Peer-Workers-MPI clusters

___Peer-Workers-MPI___ is a variation of ___Peer-Workers___ clusters, where worker processes are connected through a global MPI communicator. This is possible through _MPI.jl_ and _MPIClusterManagers.jl_. 

In what follows, we modify the ```my_second_cluster_contract``` to build a ___Peer-Workers-MPI___ cluster that will be referred by ```my_fourth_cluster``´, by using the ```cluster_type``` parameter:

```julia
my_third_cluster_contract = @cluster(cluster_type => PeerWorkersMPI,
                                     node_count => 8,   
                                     node_memory_size => @atleast(512G),
                                     accelerator_count => @just(8),
                                     accelerator_architecture => Ada)
my_fourth_cluster = @deploy my_third_cluster_contract
```


The following code launches a simple _MPI.jl_ code in _my_fourth_cluster_, using the ```@everywhere``` primitive of _Distributed.jl_. 

```julia

@everywhere nodes(my_fourth_cluster) begin
   @eval using MPI
   MPI.Init()
   rank = MPI.Comm_rank(MPI.COMM_WORLD)
   size = MPI.Comm_size(MPI.COMM_WORLD)
   @info "I am $rank among $size processes"
   root_rank = 0
   rank_sum = MPI.Reduce(rank, (x,y) -> x + y, root_rank, MPI.COMM_WORLD)
end

result = @fetchfrom ranks(my_first_cluster)[0] rank_sum
@info "The sum of ranks in the cluster is $result"
```

The parallel code calculates the sum of the ranks of the processes using the _Reduce_ collective operation of _MPI.jl_, and stores the results in the global variable _rank_sum_ of the root process, with rank 0. Then, this value is fetched by the program and assigned to the _result_ variable using ```@fetchfrom```. For that, the ```ranks``` function is used to discover the _pid_ of the root process. 


### Manager-Workers clusters


___Manager-Workers___ clusters comprise an _access node_ and a homogenous set of _compute nodes_. The compute nodes are only accessible from the access node. The instance type of the access node may differ from the instance type of the compute nodes. 

In a ___Manager-Workers___ cluster, the master process, running in the REPL or main program, is called the _driver process_. It is responsible for launching the so-called _entry process_ in the cluster's access node. In turn, the entry process launches _worker processes_ across the compute nodes, using _MPIClusterManagers.jl_. The worker processes perform the computation, while the entry process is responsible for communication between the driver and the worker processes. A global MPI communicator exists between worker processes, like in ___Peer-Workers-MPI___ clusters.

___Manager-Workers___ are useful when the compute nodes of the cluster are not directly accessible from the external network. This is a common situation in on-premises clusters, but also in clusters built from the services of cluster providers  specifically tailored to attending HPC applications.


> [!IMPORTANT]
> ___Manager-Workers___ are not natively supported by Julia, because _Distributed.jl_ does not support that worker processes create new processes, as shown below:
> ```julia
> julia>addprocs(1)
> 1-element Vector{Int64}:
> 2
> julia> @fetchfrom 2 addprocs(1)
> ERROR: On worker 2:
> Only process 1 can add or remove workers
> ```
> The _CloudClusters.jl_ developers have developed an extended version of _Distributed.jl_ that removes this limitation, making it possible to create hierarchies of Julia processes [2]. However, the multilevel extension of _Distributed.jl_ is necessary only for the access node of ___Mmanager-Workers___ cluster, where the so-called _entry processes_, launched by the master process at the REPL/program and responsible for launching the worker processes across computing nodes of the cluster, will be running. 
>
> So, only users who need to develop customized images to instantiate cluster nodes must be concerned with adapting the Julia installation for the extended _Distributed.jl_ version, and only if an image is intended to be used for master nodes of ___Manager-Workers___ clusters.
>
> The multilevel extension to _Distributed.jl_ is hosted at https://github.com/PlatformAwareProgramming/Distributed.jl, as a fork of [the original _Distributed.jl_ repository](https://github.com/JuliaLang/Distributed.jl). The README of _Distributed.jl_ explains [how to use development versions in a current Julia installation](https://github.com/JuliaLang/Distributed.jl#using-development-versions-of-this-package). In case of difficulties, the user may contact the developers of _CloudClusters.jl_. For more information about the multilevel extension of _Distributed.jl_, read the SSCAD'2024 paper [Towards multicluster computations with Julia](https://sol.sbc.org.br/index.php/sscad/article/view/31004).

The user may use the __cluster_type__ parameter to command the creation of a ___Manager-Workers___ cluster. Let us modify the ```my_first_cluster_contract``` to create a ___Manager-Workers___ cluster instead of a ___Peer-Workers___ one (default):

```julia
my_first_cluster_contract = @cluster(cluster_type => ManageWorkers,
                                     node_count => 4,
                                     node_machinetype => EC2Type_T3_xLarge)       
```

In this case, the __node_count__ parameter specifies the number of worker nodes. So, for a cluster deployed using ```my_first_cluster_contract```, five VM instances will be created, including the manager node.

The user may use "dot notation" to specify different assumptions for manager and worker nodes. For example:

```julia
my_second_cluster_contract = @cluster(cluster_type => ManageWorkers,
                                      node_count => 8,
                                      manager.node_machinetype => EC2Type_T3_xLarge,
                                      worker.accelerator_count => @just(8),
                                      worker.accelerator_architecture => Ada,   
                                      worker.accelerator_memory => @atleast(512G))
```

This contract specifies that the manager node must be a ___t3.xlarge___ VM instance, while the worker nodes will have eight NVIDIA GPUs of Ada architecture and at least 512GB of memory.

### Configuration parameters

Configuration parameters exist for the proper instantiation of clusters, whose default values are specified in the _CCconfig.toml_ file. The user may override the default values by passing configuration parameters through ___@cluster___ and ___@deploy___ operations. For example:
 
```julia
my_cluster_contract = @cluster(node_count => 4,
                               node_machinetype => EC2Type_T3_xLarge,
                               image_id => "ami-07f6c5b6de73ce7ae")

my_cluster = @deploy(my_first_cluster,
                     user => "ubuntu",
                     sshflags => "-i mykey.pem")
```

In the above code, ```image_id``` is used to specify that the EC2 image identified by ```ami-07f6c5b6de73ce7ae``` must be used when creating clusters from _my_cluster_contract_. On the other hand, ```user``` and ```sshflags``` will be used to access the nodes of _my_cluster_. For example, ```ami-07f6c5b6de73ce7ae``` may provide a set of predefined users with different privileges to access the features offered by such an image.

Currently, there are four categories of configuration parameters. They are described in the following paragraphs.

The following configuration parameters set up the SSH connections to nodes of ___Peer-Workers___ clusters and the master node of ___Master-Worker___ clusters, i.e., those nodes that are externally accessible:
* __user__::```String```, the user login to access VM instances (e.g., ```user@xxx.xxx.xxx.xxx```, where ```xxx.xxx.xxx.xxx``` is the public IP of the VM instance);
* __sshflags__::```String```, the flags that must be passed to the ssh command to access the VM instances;
* __tunneled__::```Bool```, a keyword argument to be passed to ```addprocs``` to determine whether or not ssh access should be [tunneled](https://www.ssh.com/academy/ssh/tunneling).

The following configuration parameters apply to cluster nodes of any cluster type:
* __exename__::```String```, the full path to the ```julia``` executable (e.g., /home/ubuntu/.juliaup/bin/julia);
* __exeflags__::```String```, flags to be passed to the ```julia``` executable when starting processes on cluster nodes;
* __directory__::```String```, the current directory of the ```julia``` execution in the VM instance.

The following configuration parameters apply to nodes of ___Peer-Workers-MPI___ and worker nodes of ___Manager-Workers___ clusters, i.e., the ones with MPI-based message-passing enabled:
* __threadlevel__::```Symbol```, a keyword argument that is passed to ```MPI.Init```, whose possible values are: [```single```,```:serialized```, ```:funneled```, ```:multiple```](https://juliaparallel.org/MPI.jl/stable/reference/environment/#MPI.ThreadLevel); 
* __mpiflags__::```String```, a keyword argument that passed to MPI (e.g., ```"--map-by node --hostfile /home/ubuntu/hostfile"```). 

The last set of configuration parameters depends on the IaaS provider selected through __@resolve__. For AWS EC2, they are:
* __imageid__::```String```, the _id_ of the image used to instantiate the VM instances that form the cluster nodes;
* __subnet_id__::```String```, the _id_ of a subnet for the communication between VM instances that form the cluster nodes;
* __placement_group__::```String```, the _id_ of an existing placement group where the user wishes to colocate the VM instances that form the cluster nodes (the default is to create a temporary placement group);
* __security_group_id__: :```String```, the _id_ of an existing security group for the VM instances that form the cluster nodes.

# Publications

* Francisco Heron de Carvalho Junior, João Marcelo Uchoa de Alencar, and Claro Henrique Silva Sales. 2024. ___Cloud-based parallel computing across multiple clusters in Julia___. In Proceedings of the _28th Brazilian Symposium on Programming Languages_ (SBLP'2024), September 30, 2024, Curitiba, Brazil. SBC, Porto Alegre, Brasil, 44-52. DOI: https://doi.org/10.5753/sblp.2024.3470.

* Francisco Heron de Carvalho Junior and Tiago Carneiro. 2024. ___Towards multicluster computations with Julia___. In Proceedings of the XXV Symposium on High-Performance Computational Systems (SSCAD’2024), October 25, 2024, São Carlos, Brazil. SBC, Porto Alegre, Brazil. DOI: https://doi.org/10.5753/sscad.2024.244307

