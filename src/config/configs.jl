
abstract type Localhost <: OnPremises end

function readCCConfig(config_file::String)

    # read the platform description file (default to the current directory)
    configpath = get(ENV,"CLOUD_CLUSTERS_CONFIG", pwd())

    filename = string(configpath, "/$config_file")

    @info "reading configurations from $filename"

    ccconfig_toml =   
         try
            io = open(filename)
            contents = read(io,String)
            close(io)
            contents
         catch
            default_location = "/etc/$config_file"
            try
                # defaul system location
                io = open(default_location)
                contents = read(io,String)
                close(io)
                contents
            catch
                @info "The configuration file ($config_file) was not found."
     
     #           dpf_path = @get_scratch!("default_platform_path")
     #           dpf_url = "https://raw.githubusercontent.com/PlatformAwareProgramming/PlatformAware.jl/manager/src/features/default/Platform.toml"
     #           dpf_fname =  joinpath(dpf_path, basename(dpf_url))
     #           try_download(dpf_url, dpf_fname)

     #           read(dpf_fname,String)
            end
         end
    
    #@info "=====> $ccconfig_toml"
    if isnothing(ccconfig_toml)
        @error "The configuration file ($config_file) was not found."
        return nothing
    end

    TOML.parse(ccconfig_toml)    
end

function loadDefaults(_::Type{Provider}, ccconfig_dict)

    defaults_dict = Dict()

    haskey(ccconfig_dict["defaults"], "user") && (defaults_dict[:user] = ccconfig_dict["defaults"]["user"])
    haskey(ccconfig_dict["defaults"], "exename") && (defaults_dict[:exename] = ccconfig_dict["defaults"]["exename"])
    haskey(ccconfig_dict["defaults"], "exeflags") && (defaults_dict[:exeflags] = ccconfig_dict["defaults"]["exeflags"])
    haskey(ccconfig_dict["defaults"], "directory") && (defaults_dict[:directory] = ccconfig_dict["defaults"]["directory"])
    haskey(ccconfig_dict["defaults"], "tunneled") && (defaults_dict[:tunneled] = ccconfig_dict["defaults"]["tunneled"])
    haskey(ccconfig_dict["defaults"], "threadlevel") && (defaults_dict[:threadlevel] = Symbol(ccconfig_dict["defaults"]["threadlevel"]))
    haskey(ccconfig_dict["defaults"], "mpiflags") && (defaults_dict[:mpiflags] = ccconfig_dict["defaults"]["mpiflags"])
    haskey(ccconfig_dict["defaults"], "sshflags") && (defaults_dict[:sshflags] = ccconfig_dict["defaults"]["sshflags"])
    
    return defaults_dict
end

_providers = [Provider, Localhost, AmazonEC2, GoogleCloud]

defaults_dict = Dict()

function load!()
    ccconfig_dict = readCCConfig("CCconfig.toml")
    for provider_type in _providers
        if !isnothing(ccconfig_dict)
            defaults_dict[provider_type] = loadDefaults(provider_type, ccconfig_dict) 
        else
            @error "Default configuration of $provider_type is empty"
        end
    end
end

function cluster_defaultconfig(provider_type)
    defaults_dict[provider_type]
end

function cluster_defaultconfig()
    defaults_dict[Provider]
end

function cluster_providers()
    Vector(_providers)[2:end]
end