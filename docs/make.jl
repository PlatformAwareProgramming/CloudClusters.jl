using Documenter, CloudClusters

makedocs(sitename="CloudClusters.jl")

repo = "github.com/PlatformAwareProgramming/CloudClusters.jl.git"

withenv("GITHUB_REPOSITORY" => repo) do
  deploydocs(; repo, versions=["stable" => "v^", "dev" => "dev"], push_preview = true, forcepush = true)
end
