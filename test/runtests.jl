using CloudClusters
using Test  

# list of tests
testfiles = [
    "basics.jl"
]

@testset "CloudClusters.jl" begin
    for testfile in testfiles
        println("Testing $testfile...")
        include(testfile)
    end
end