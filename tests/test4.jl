using GoogleCloud
using JSON

session = GoogleSession("/home/.gcp/credentials.json", ["cloud-platform"])
set_session!(compute, session)
instance_json = String(compute(:Instance, :list, "cloudclusters", "us-central1-a"))
instance_dict = JSON.parse(instance_json)
println(instance_dict["items"][1])
