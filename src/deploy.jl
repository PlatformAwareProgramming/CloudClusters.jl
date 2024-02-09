














# indexed by wid
cluster_deploy_info = Dict()


function perform_deploy(cluster_handle)

    cluster_type, features = cluster_info[cluster_handle]

    wid = deploy_cluster(cluster_type, features)

    return wid
end

function perform_interrupt(wid)
    interrupt_cluster(cluster_deploy_info[wid][:cluster_type], cluster_deploy_info[wid])
end

function perform_continue(wid)
    continue_cluster(cluster_deploy_info[wid][:cluster_type], cluster_deploy_info[wid])
end

function perform_terminate(wid)
    terminate_cluster(cluster_deploy_info[wid][:cluster_type], cluster_deploy_info[wid])
end