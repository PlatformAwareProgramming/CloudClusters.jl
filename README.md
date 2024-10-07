# CloudClusters.jl

_A package for creating and deploying Julia computations on cloud-based clusters on the infrastructure of IaaS providers it supports._

> [!NOTE]
> _Currently, it only supports [EC2](https://aws.amazon.com/ec2/). Ask us about the progress with [GCP](https://cloud.google.com/) and [Azure](https://azure.microsoft.com/)._ Collaborators are wellcome.

## Target users

_CloudClusters.jl_ targets users of the Julia programming language who want to take advantage of on-demand access to cutting-edge computing resources offered by IaaS providers to meet high-performance computing (HPC) requirements of applications of their interest.

## Pre-requisites

# Tutorial

We assume that the authentication to the IaaS provider is correctly configured in the environment where the Julia REPL session or standalone program will execute. 
In what follows, we teach how to create clusters and deploy computations on them using _Distributed.jl_ primitives.

## How to create clusters (the simplest way)

_CloudClusters.jl_ offers the following six primitives, implemented as _macros_, to create and manage the lifecycle of a cluster: __@cluster__, __@resolve__, __@deploy__, __@terminate__, __@interrupt__, __@resume__. They are explained in the following paragraphs, with a simple example you can try to reproduce in a REPL session. 
It is assumed the environment is configured to access the AWS EC2 services and a _CCconfig.EC2.toml_ file is available in an accessible path.

First, let us examine a simple scenario where a user wants to create a cluster comprising 4 ___t3.xlarge___ virtual machines (VM) instances through the AWS EC2 services. For that, the user must use the __@cluster__ macro, passing the number of nodes and instance type as arguments.

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

For each node, a _worker process_ is created, whose _pids_ may be inspected using the ___workers___ function, passing the cluster handle as an argument. In the following code, the _pids_ of the cluster nodes are 2, 3, 4, and 5.

```julia
julia> workers(my_first_cluster)
4-element Vector{Int64}
2
3
4
5
```

The cluster may be interrupted through the ___@interrupt___ macro: 

```julia
@interrupt my_first_cluster
```
After ___@interrupt___ completes, the VM instances of cluster nodes are paused/stopped, and can be resumed/restarted through the ___@resume___ macro:

```julia
@resume my_first_cluster
```
It is important to notice that ___@interrupt___ finishes the worker processes across all cluster nodes. So, it does not automatically preserve the state of undergoing computations. The interruption of a cluster may be used with the only purpose to pause VM instances underying the cluster nodes. The __@resume___ operation creates a fresh set of worker processes, with different _pids_.

Finally, a cluster may be finished/terminated using the ___@terminate___ macro:

```julia
@terminate my_first_cluster
```



## How to run computations on a cluster

## How to run computations on multiple clusters

## How to reconnect to a non-terminated cluster

## The non-macro interface

## Working with cluster contracts (the advanced way)



