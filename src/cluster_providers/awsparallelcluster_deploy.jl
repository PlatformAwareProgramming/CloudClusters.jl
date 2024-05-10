abstract type AWSParalleClusterProvider <: ClusterProvider end



function deploy_cluster(type::Type{<: AWSParalleClusterProvider}, features)
    
end


#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(wid, type::Type{AWSParalleClusterProvider})
    
end

#==== CONTINUE CLUSTER ====#

function continue_cluster(wid, type::Type{AWSParalleClusterProvider})
    
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(wid, type::Type{AWSParalleClusterProvider})
    
end