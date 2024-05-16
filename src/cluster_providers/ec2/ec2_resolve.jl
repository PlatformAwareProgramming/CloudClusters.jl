db = PlatformAware.readCloudInstancesDB(AmazonEC2)

ACCELERATOR_TYPE_INDEX = 3
ACCELERATOR_ARCH_INDEX = 6
ACCELERATOR_MODEL_INDEX = 2
PROCESSOR_MODEL_INDEX = 8
PROCSSOR_ARCH_INDEX = 7

for (instance_type, instance_info) in db

    instance_info["node_provider"] = "AmazonEC2"

    accelerator_desc = instance_info["accelerator"]
    accelerator_specs = PlatformAware.lookupDB(PlatformAware.accelerator_dict[], accelerator_desc) 
    if !isnothing(accelerator_specs)
        accelerator_type = accelerator_specs[ACCELERATOR_TYPE_INDEX]
        accelerator_arch = accelerator_specs[ACCELERATOR_ARCH_INDEX]
        accelerator_model = accelerator_specs[ACCELERATOR_MODEL_INDEX]

    else
        accelerator_type = "AcceleratorType"
        accelerator_arch = "AcceleratorArchitecture"
        accelerator_model = "Accelerator"
    end 

    processor_desc = instance_info["processor"]
    processor_specs = PlatformAware.lookupDB(PlatformAware.processor_dict[], processor_desc)
    if !isnothing(processor_specs)
        processor_model = processor_specs[PROCESSOR_MODEL_INDEX]
        processor_arch = processor_specs[PROCSSOR_ARCH_INDEX]
    else
        processor_model = "Processor"
        processor_arch = "ProcessorMicroarchitecture"
    end

    instance_info["accelerator_type"] = accelerator_type
    instance_info["accelerator_architecture"] = accelerator_arch
    instance_info["accelerator"] = accelerator_model
    instance_info["processor"] = processor_model
    instance_info["processor_microarchitecture"] = processor_arch

    parameters = Vector()
    push!(parameters, :resolve)
    for name in instance_features_order
        par = instance_info[string(name)]
        ft = PlatformAware.getFeature(name, par, instance_features, instance_features_type)
        push!(parameters, :($name::Type{>:$ft}))
    end

    resolve_decl = Expr(:function, Expr(:call, parameters...), Expr(:block, Expr(:return, instance_type)))
    eval(resolve_decl)

end

