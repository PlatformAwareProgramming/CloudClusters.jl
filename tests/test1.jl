using GoogleCloud
using GoogleCloud.api 
using GoogleCloud.root

using JSON

# CHECK SCOPES: https://developers.google.com/identity/protocols/oauth2/scopes

session = nothing

function session_init()
    global session = GoogleSession("/home/makai/Desktop/CloudCluster/CloudClusters.jl/tests/creds.json", ["cloud-platform"])
    set_session!(storage, session)
    set_session!(compute, session)
end

function print_session()
    println(session)
end

function list_vm()
    return compute(:Instance, :list, "cloudclusters", "us-central1-a")
end

function create_vm()
    instance = Dict(
        "disks" => [Dict(
            "autoDelete" => true,
            "boot" => true,
            "initializeParams" => Dict(
                "diskSizeGb" => 50,
                "sourceImage" => "projects/ubuntu-os-pro-cloud/global/images/ubuntu-pro-2404-noble-amd64-v20241115"
            ),
            "mode" => "READ_WRITE",
            "type" => "PERSISTENT"
        )],
        "machineType" => "zones/us-central1-a/machineTypes/e2-standard-2",
        "name" => "example-instance2",
        "networkInterfaces" => [Dict(
            "accessConfigs" => [Dict(
                "name" => "external-nat",
                "type" => "ONE_TO_ONE_NAT"
            )],
            "network" => "https://www.googleapis.com/compute/v1/projects/cloudclusters/global/networks/default"
        )],
        "metadata" => 
            "items" => Dict(
                "key" => "startup-script",
                "value" => "#! /bin/bash"
        )
    )

    compute(:Instance, :insert, "cloudclusters", "us-central1-a"; data=instance)
end

function delete_vm()
    compute(:Instance, :delete, "cloudclusters", "us-central1-a", "example-instance")
end

function metadata()
    project = "cloudclusters"
    ssh_key = "aaaaaa"

    project_dict = JSON.parse(String(GCPAPI.compute(:Project, :get, project)))

    fingerprint = project_dict["commonInstanceMetadata"]["fingerprint"]
    
    sanitized_ssh_key = replace(ssh_key, r"[\x00-\x1F\x7F]" => "")  # remove ASCII control characters

    metadata_dict = Dict(
        "items" => [
            Dict(
                "key" => "ssh-keys",
                "value" => sanitized_ssh_key
            )
        ],
        "fingerprint" => fingerprint
    )

    GCPAPI.compute(:Project, :setCommonInstanceMetadata, project; data=metadata_d)
end

session_init()
metadata()

