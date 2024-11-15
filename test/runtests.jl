using CloudClusters
using Test  
using Distributed

# list of tests
testfiles = [
    "localcluster.jl" 
]

@testset "CloudClusters.jl" begin
    for testfile in testfiles
        println("Testing $testfile...")
        include(testfile)
    end
end