# CloudClusters.jl

_A package for creating, using, and managing the lifecycle of cloud-based clusters deployed at the infrastructure of IaaS providers._

> [!NOTE]
> _Currently, it only supports [EC2](https://aws.amazon.com/ec2/). Ask us about the progress with [GCP](https://cloud.google.com/) and [Azure](https://azure.microsoft.com/)._ Collaborators are wellcome.

## Target users

_CloudClusters.jl_ targets users of the Julia programming language who want to take advantage of on-demand access to cutting-edge computing resources offered by IaaS providers to meet high-performance computing (HPC) requirements of applications of their interest.
   
## Pre-requisites

# Tutorial

We assume that the authentication to the IaaS provider is correctly configured in the environment where the Julia REPL session or standalone program will execute. 
In what follows, we teach how to create clusters and deploy computations on them using _Distributed.jl_ primitives.

## How to create a cluster (the simplest way)

_CloudClusters.jl_ offers the following six primitives, implemented as _macros_, to create and manage the lifecycle of a cluster: __@cluster__, __@resolve__, __@deploy__, __@terminate__, __@interrupt__, __@resume__. They are explained in the following paragraphs, with a simple example you can try to reproduce in a REPL session. 
It is assumed the environment is configured to access the AWS EC2 services and a _CCconfig.EC2.toml_ file is available in an accessible path.

First, let us examine a simple scenario where a user wants to create a cluster comprising four ___t3.xlarge___ virtual machines (VM) instances through the AWS EC2 services. For that, the user must use the __@cluster__ macro, passing the number of nodes and instance type as arguments.

```julia
using CloudClusters
using PlatformAware

my_first_cluster_contract = @cluster  node_count => 4  node_machinetype => EC2Type_T3_xLarge

```

The __@cluster__ macro will not instantiate the cluster yet. It will create a _cluster contract_, from which the user can create one or more clusters. 

The variable ```my_first_cluster_contract``` receives a _contract handle_. In _CloudClusters.jl_, a handle is a symbol comprising 15 randomly calculated lower- and upper-case alphabetic characters (e.g.,```:FXqElAnSeTEpQAm``` ). Since they are symbols, they are printable and may be used directly to refer to a cluster contract.

A cluster contract must be resolved to be able to instantiate clusters from it. For that, the user needs to apply __@resolve__, as below:

```julia
@resolve my_first_cluster_contract
```

The __@resolve__ macro will trigger a resolution procedure to calculate which instance type provided by a supported IaaS provider satisfies the contract. For this simple contract, the response is explicitly specified in the exemplified contract, i.e., the ___t3.xlarge___ instance type offered by AWS EC2. For more advanced contract specifications, where cluster contract resolution shows its power, the reader can read the section [Working with cluster contracts (the advanced way)](https://github.com/PlatformAwareProgramming/CloudClusters.jl/edit/decarvalhojunior-fh-patch-1-README/README.md#working-with-cluster-contracts-the-advanced-way).

A cluster may be instantiated by using ___@deploy___:

```julia
my_first_cluster = @deploy my_first_cluster
```

The __@deploy__ macro will create a 4-node cluster comprising ___t3.xlarge___ AWS EC2 instances, returning a cluster handle in the ```my_first_cluster``` variable. 

The process of creating instances, until they are ready to be connected to the master process through worker processes instantiated in each of them via _Distributed.jl_, can be lengthy, depending on the provider.

For each cluster node, a _worker process_ is created, whose _pids_ may be inspected using the ___workers___ function, passing the cluster handle as an argument. In the following code, the _pids_ of the processes at the cluster nodes are 2, 3, 4, and 5. 

```julia-repl
julia> workers(my_first_cluster)
4-element Vector{Int64}
2
3
4
5
```

## Running computations on the cluster

The user may execute parallel computations on the cluster by using _Distributed.jl_ to communicate with cluster nodes from the master process and _MPI.jl_ to implement the parallel computation between cluster nodes. 

The following code launches a simple _MPI.jl_ code in the _my_first_cluster_, using the ```@everywhere``` primitive of _Distributed.jl_. 

```julia
@everywhere workers(my_first_cluster) begin
   @eval using MPI
   MPI.Init()
   rank = MPI.Comm_rank(MPI.COMM_WORLD)
   size = MPI.Comm_size(MPI.COMM_WORLD)
   @info "I am $rank among $size processes"
   root_rank = 0
   rank_sum = MPI.Reduce(rank, (x,y) -> x + y, root_rank, MPI.COMM_WORLD)
end

result = @fetchfrom ranks(my_first_cluster0)[0] rank_sum
@info "The sum of ranks in the cluster is $result"
```

The parallel code calculates the sum of the ranks of the processes using the _Reduce_ collective operation of _MPI.jl_, and stores the results in the global variable _rank_sum_ of the root process, with rank 0. Then, this value is fetched by the program and assigned to the _result_ variable using ```@fetchfrom```. For that, the ```ranks``` function is used to discover the _pid_ of the root process.

## Multiple clusters

The user can create as many cluster contracts as necessary, as well as as many clusters from them. For example, the following code creates a second cluster contract, named ```my_second_cluster_contract```, asking for a cluster of eight VM instances equipped with GPUs of NVIDIA Turing architecture having at least 16GB of memory. Then, it creates two clusters from ```my_second_cluster_contract```. 

```julia

my_second_cluster_contract = @cluster(nodes_count => 8,
                                      accelerator_count => @just(1),
                                      accelerator_architecture => Turing,
                                      accelerator_memory => @atleast(16G))

@resolve my_second_cluster_contract

my_second_cluster = @deploy my_second_cluster_contract
my_third_cluster = @deploy my_second_cluster_contract
```

In the above code, notice the advanced use of cluster contracts, by asking for instance types that satisfy a set of assumptions. At the time this tutorial was written, the AWS EC2 instance type that satisfies these assumptions is ___g4dn.xlarge___, equipped with NVIDIA Tesla T4 GPUs.

Now, there are three available clusters. The _pids_ of the last two ones may be inspected:

```julia-repl
julia> workers(my_second_cluster)
8-element Vector{Int64}
6
7
8
9
10
11
12
13

julia> workers(my_third_cluster)
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

The user may orchestrate all the deployed clusters to execute computations of their interest, independent of their provider. However, it is important to notice that _MPI.jl_ computations are restricted to be performed between the processes of the same cluster. Communication operations between the nodes of different clusters may still be performed through _Distributed.jl_, or using the master process as an intermediary. However, inter-cluster communication must be employed with care, only when strictly necessary and asynchronously, if possible, overlapping it with computations, due to the high communication overhead between clusters.

## Interrupting and resuming a cluster

A cluster may be interrupted through the ___@interrupt___ macro: 

```julia
@interrupt my_first_cluster
```
The effect of ___@interrupt___ is pausing/stopping the VM instances of the cluster nodes. 

An interrupted cluster can be put back to the running state through the ___@resume___ macro:

```julia
@resume my_first_cluster
```
The resuming operation creates a fresh set of worker processes, with new _pids_.

> [!NOTE]
> It is important to notice that ___@interrupt___ does not preserve the state of undergoing computations in the cluster, since it kills the worker processes running at the cluster nodes. The interruption of a cluster may be used to avoid the cost of cloud resources that are not currently being used. It is the user's responsibility to save the state of undergoing computations in a cluster to be interrupted and reload the state after resuming whenever necessary. 

## Restarting processes

A user can restart the processes at the cluster nodes by using the ___@restart___ macro: 

```julia
@restart my_first_cluster
```

The restart procedure kills all the current processes at the cluster nodes, losing their current state, and creates new processes, with new pids. 

## Terminating a cluster

Finally, a cluster may be finished/terminated using the ___@terminate___ macro:

```julia
@terminate my_first_cluster
```

After terminating, the cloud resources associated with the cluster are freed.

## How to reconnect to a non-terminated cluster

If a cluster was not terminated in the execution of a standalone program or REPL session, the user may reconnect it by making a call to the ___@reconnect___ macro. For example:

```julia
@reconnect :FXqElAnSeTEpQAm
```

In the above code, ```:FXqElAnSeTEpQAm``` is the handle of a cluster not terminated in a previous execution session. But how may the user discover the cluster handle of a non-terminated cluster? After a crash, for example. For that, the user may call the ___@clusters___ macro, which returns a list of non-terminated clusters in previous sessions that may be reconnected:

```julia
julia> @clusters
[ Info: PeerWorkers FXqElAnSeTEpQAm, created at 2024-10-08T09:12:40.847 on PlatformAware.AmazonEC2
1-element Vector{Any}:
 Dict{Any, Any}(:handle => :FXqElAnSeTEpQAm, :provider => PlatformAware.AmazonEC2, :type => PeerWorkers, :timestamp => Dates.DateTime("2024-10-08T09:12:40.847"))
```



## Working with cluster contracts (the advanced way)



