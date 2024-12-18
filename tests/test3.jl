using PlatformAware

include("../src/CloudClusters.jl")
using .CloudClusters

#= cc = @cluster(processor => Processor,
                accelerator_architecture => AcceleratorArchitecture,
                processor_manufacturer => Manufacturer,
                storage_type => StorageType,
                node_memory_size => Tuple{AtLeast4G, AtMost4G, 4.294967296e9},
                storage_size => Tuple{AtLeast0, AtMostInf, Q} where Q,
                node_provider => GoogleCloud,
                node_vcpus_count => Tuple{AtLeast4, AtMost4, 4.0},
                accelerator_count => Tuple{AtLeast0, AtMost1, 0.0},
                network_performance => Tuple{AtLeast8G, AtMost8G, 8.589934592e9},
                accelerator => Accelerator, accelerator_type => AcceleratorType,
                accelerator_memory_size => Tuple{AtLeast0, AtMost1, 0.0},
                accelerator_manufacturer => Manufacturer,
                node_machinetype => PlatformAware.GCPType_E2_Standard4,
                processor_microarchitecture => ProcessorMicroarchitecture,
                node_count => 4) =#

                #PlatformAware.GCPType_E2_Micro.api_name
cc = @cluster  node_machinetype => PlatformAware.GCPType_E2_Micro  node_count => 4


println(@resolve cc)
my_first_cluster = @deploy cc