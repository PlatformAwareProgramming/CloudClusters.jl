using TOML

function readCCConfig()

    # read the platform description file (default to the current directory)
    filename = get(ENV,"CLOUD_CLUSTERS_CONFIG","CCconfig.toml")
    
    @info "reading configurations from $filename"

    ccconfig_toml =   
         try
            io = open(filename)
            read(io,String)
         catch
            default_location = "/etc/CCconfig.toml"
            try
                # defaul system location
                io = open(default_location)
                contents = read(io,String)
                close(io)
                contents
            catch
                @info "The configuration file (CCconfig.toml) was not found."
     
     #           dpf_path = @get_scratch!("default_platform_path")
     #           dpf_url = "https://raw.githubusercontent.com/PlatformAwareProgramming/PlatformAware.jl/master/src/features/default/Platform.toml"
     #           dpf_fname =  joinpath(dpf_path, basename(dpf_url))
     #           try_download(dpf_url, dpf_fname)

     #           read(dpf_fname,String)
            end
         end
    
        TOML.parse(ccconfig_toml)    
end



function load!()
    ccconfig_dict = readCCConfig() 
    loadDefaults(ccconfig_dict)
end

defaults_dict = Dict()

function loadDefaults(ccconfig_dict)

    defaults_dict[:imageid] = ccconfig_dict["defaults"]["imageid"]
    defaults_dict[:user] = ccconfig_dict["defaults"]["user"]
    defaults_dict[:keyname] = ccconfig_dict["defaults"]["keyname"]
    defaults_dict[:exename] = ccconfig_dict["defaults"]["exename"]
    defaults_dict[:exeflags] = ccconfig_dict["defaults"]["exeflags"]
    defaults_dict[:tunneled] = ccconfig_dict["defaults"]["tunneled"]
    defaults_dict[:threadlevel] = Symbol(ccconfig_dict["defaults"]["threadlevel"])
    defaults_dict[:mpiflags] = ccconfig_dict["defaults"]["mpiflags"]

    @info defaults_dict
end