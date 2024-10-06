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

## How to create one or more clusters (the simplest way)

_CloudClusters.jl_ offers six primitives to create and manage the lifecycle of a cluster: __@cluster__, __@resolve__, __@deploy__, __@terminate__, __@interrupt__, __@resume__. They are explained below, with a simple example that you can try to reproduce in a REPL session.

### @cluster

### @resolve

### @deploy

### @terminate

### @interrupt

### @resume

## Running computations on a cluster

## Running computations on multiple clusters

## Reconnecting to a non-terminated cluster

## Working with cluster contracts (the advanced way)



