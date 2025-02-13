



db = PlatformAware.readCloudInstancesDB(AmazonEC2)

ACCELERATOR_TYPE_INDEX = 3
ACCELERATOR_ARCH_INDEX = 6
ACCELERATOR_MEM_SIZE = 7
ACCELERATOR_MODEL_INDEX = 2
ACCELERATOR_MAN_INDEX = 4
PROCESSOR_MODEL_INDEX = 8
PROCESSOR_ARCH_INDEX = 7
PROCESSOR_MAN_INDEX = 9

for (instance_type, instance_info) in db

    instance_info["node_provider"] = "AmazonEC2" 

    accelerator_desc = instance_info["accelerator"]
    accelerator_specs = PlatformAware.lookupDB(PlatformAware.accelerator_dict[], accelerator_desc) 
    if !isnothing(accelerator_specs)
        accelerator_type = accelerator_specs[ACCELERATOR_TYPE_INDEX]
        accelerator_arch = accelerator_specs[ACCELERATOR_ARCH_INDEX]
        accelerator_model = accelerator_specs[ACCELERATOR_MODEL_INDEX]
        accelerator_man = accelerator_specs[ACCELERATOR_MAN_INDEX]
        accelerator_memory_size = accelerator_specs[ACCELERATOR_MEM_SIZE]
    else
        #if accelerator_desc != "na"
        #    @warn "The $accelerator_desc accelerator is not registered in the database."
        #end
        accelerator_type = "AcceleratorType"
        accelerator_arch = "AcceleratorArchitecture"
        accelerator_man = "Manufacturer"
        accelerator_model = "Accelerator"
        accelerator_memory_size = "0"
    end 

    processor_desc = instance_info["processor"]
    processor_specs = PlatformAware.lookupDB(PlatformAware.processor_dict[], processor_desc)
    if !isnothing(processor_specs)
        processor_model = processor_specs[PROCESSOR_MODEL_INDEX]
        processor_arch = processor_specs[PROCESSOR_ARCH_INDEX]
        processor_man = processor_specs[PROCESSOR_MAN_INDEX]
    else
        #if processor_desc != "na"
        #    @warn "The $processor_desc processor is not registered in the database."
        #end
        processor_model = "Processor"
        processor_arch = "ProcessorMicroarchitecture"
        processor_man = "Manufacturer"
    end

    instance_info["accelerator_type"] = accelerator_type
    instance_info["accelerator_architecture"] = accelerator_arch
    instance_info["accelerator_manufacturer"] = accelerator_man
    instance_info["accelerator_memory_size"] = accelerator_memory_size
    instance_info["accelerator"] = accelerator_model
    instance_info["processor"] = processor_model
    instance_info["processor_microarchitecture"] = processor_arch
    instance_info["processor_manufacturer"] = processor_man

    parameters, instance_feature_table = fetch_features(instance_info, keytype = String)

    instance_type_table[instance_type] = instance_feature_table

    resolve_decl = Expr(:function, Expr(:call, parameters...), Expr(:block, Expr(:return, (instance_type, PlatformAware.AmazonEC2))))
    eval(resolve_decl)

end



