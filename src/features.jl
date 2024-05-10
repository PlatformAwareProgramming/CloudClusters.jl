abstract type ClusterProvider end
abstract type EC2Cluster <: ClusterProvider end

instance_features_order = [:provider,
                           :instance_type,
                           :memory_size,
                           :compute_units,
                           :vcpus_unit,
                           :accelerator_count,
                           :accelerator_type,
                           :accelerator_arch, 
                           :accelerator_model, 
                           :processor_model, 
                           :processor_arch, 
                           :storage_type, 
                           :interconnection_type]

instance_features = Dict(:provider => nothing,            #TODO
                         :instance_type => nothing,       #TODO
                         :memory_size => nothing,         #TODO
                         :compute_units => nothing,       #TODO
                         :vcpus_unit => nothing,          #TODO
                         :accelerator_count => nothing,   #TODO
                         :accelerator_type => nothing,    #TODO
                         :accelerator_arch => nothing,    #TODO
                         :accelerator_model => nothing,   #TODO
                         :processor_model => nothing,     #TODO
                         :processor_arch => nothing,      #TODO
                         :storage_type => nothing,        #TODO
                         :interconnection_type => nothing #TODO
                     )

