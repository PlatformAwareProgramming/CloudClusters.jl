abstract type AWSParalleClusterType <: ClusterType end



function deploy_cluster(type::Type{<: AWSParalleClusterType}, features)
    
end


#==== INTERRUPT CLUSTER ====#

function interrupt_cluster(wid, type::Type{AWSParalleClusterType})
    
end

#==== CONTINUE CLUSTER ====#

function continue_cluster(wid, type::Type{AWSParalleClusterType})
    
end

#==== TERMINATE CLUSTER ====#

function terminate_cluster(wid, type::Type{AWSParalleClusterType})
    
end