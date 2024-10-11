#abstract type ClusterProvider end
#abstract type EC2Cluster <: ClusterProvider end

instance_features_order = [:node_provider,
                           :node_machinetype,
                           :node_memory_size,
                         #  :node_ecu_count,
                           :node_vcpus_count,
                           :accelerator_count,
                           :accelerator_type,       #
                           :accelerator_architecture,       #
                           :accelerator_manufacturer,
                           :accelerator_memory_size,
                           :accelerator, 
                           :processor, 
                           :processor_manufacturer,
                           :processor_microarchitecture,         #
                           :storage_type, 
                           :storage_size,           
                           :network_performance]

instance_features = Dict(:node_provider => CloudProvider,               
                         :node_machinetype => MachineType,       
                         :node_memory_size => Tuple{AtLeast0,AtMostInf,Q} where Q,         
                        # :node_ecu_count => Tuple{AtLeast0,AtMostInf,Q} where Q,       
                         :node_vcpus_count => Tuple{AtLeast1,AtMostInf,Q} where Q,          
                         :accelerator_count => Tuple{AtLeast0,AtMostInf,Q} where Q,   
                         :accelerator_type => AcceleratorType,    
                         :accelerator_architecture => AcceleratorArchitecture,    
                         :accelerator_manufacturer => Manufacturer,
                         :accelerator_memory_size => Tuple{AtLeast0,AtMostInf,Q} where Q,
                         :accelerator => Accelerator,   
                         :processor => Processor,     
                         :processor_manufacturer => Manufacturer,
                         :processor_microarchitecture => ProcessorMicroarchitecture,      
                         :storage_type => StorageType,        
                         :storage_size => Tuple{AtLeast0,AtMostInf,Q} where Q,        
                         :network_performance => Tuple{AtLeast0,AtMostInf,Q} where Q 
                     )

#@enum FeatureType qualifier=1 api_qualifier quantifier

instance_features_type = Dict(
                           :node_provider => PlatformAware.qualifier,
                           :node_machinetype => PlatformAware.qualifier,
                           :node_memory_size => PlatformAware.quantifier,
                         #  :node_ecu_count => PlatformAware.quantifier,
                           :node_vcpus_count => PlatformAware.quantifier,
                           :accelerator_count => PlatformAware.quantifier,
                           :accelerator_type => PlatformAware.qualifier,       #
                           :accelerator_architecture => PlatformAware.qualifier,       #
                           :accelerator_manufacturer => PlatformAware.qualifier,
                           :accelerator_memory_size => PlatformAware.quantifier,
                           :accelerator => PlatformAware.qualifier, 
                           :processor => PlatformAware.qualifier, 
                           :processor_manufacturer => PlatformAware.qualifier,
                           :processor_microarchitecture => PlatformAware.qualifier,         #
                           :storage_type => PlatformAware.qualifier, 
                           :storage_size => PlatformAware.quantifier,           
                           :network_performance => PlatformAware.quantifier
 )
