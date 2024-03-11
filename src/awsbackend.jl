
#=
For this module to work, you`ll need AWS credentials in the ${HOME}/.aws directory. 
=# 

#=
1. Create placement group.
2. Create EFS Filesystem.
3. Create EC2 instances and attach them to the EFS.
=# 

using Random
using AWS: @service
@service Ec2 
@service Efs

#=
Grupo de Alocação
=#
function create_placement_group(name)
    params = Dict(
        "GroupName" => name, 
        "Strategy" => "cluster",
        "TagSpecification" => 
            Dict(
                "ResourceType" => "placement-group",
                "Tag" => [Dict("Key" => "cluster", "Value" => name)]
            )
        )
    Ec2.create_placement_group(params)
end

#=
Foi preciso editar as linhas 9556 e 9569 do arquivo ~/.julia/packages/AWS/3Zvz1/src/services/ec2.jl e trocar o valor de groupName para GroupName.
=#
function delete_placement_group(name)
    params = Dict("GroupName" => name)
    Ec2.delete_placement_group(name)
end

#=
Grupo de Segurança 
=#
function create_security_group(name, description)
    params = Dict(
        "TagSpecification" => 
            Dict(
                "ResourceType" => "security-group",
                "Tag" => [Dict("Key" => "cluster", "Value" => name)]
            )
    )
    id = Ec2.create_security_group(name, description, params)["groupId"]
    params = Dict(
        "GroupId" => id, 
        "CidrIp" => "0.0.0.0/0",
        "IpProtocol" => "tcp",
        "FromPort" => 22,
        "ToPort" => 22)
    Ec2.authorize_security_group_ingress(params)
    id
end

function delete_security_group(id)
    Ec2.delete_security_group(Dict("GroupId" => id))
end

#=
Instâncias
Foi preciso editar as linhas 29578 e 29598 do arquivo ~/.julia/packages/AWS/3Zvz1/src/services/ec2.jl e trocar o valor de clientToken para ClientToken.
Precisa usar no mínimo c6i.large.
=#

function create_instances(name, instance_type, image_id, key_name, count, placement_group, security_group_id)
    params = Dict(
        "InstanceType" => instance_type,
        "ImageId" => image_id,
        "KeyName" => key_name,
        "Placement" => Dict("GroupName" => placement_group),
        "SecurityGroupId" => [security_group_id],
        "TagSpecification" => 
            Dict(
                "ResourceType" => "instance",
                "Tag" => [Dict("Key" => "cluster", "Value" => name)]
            )
    )
    instances = Ec2.run_instances(count,count,params)
    number_of_instances = length(instances["instancesSet"]["item"])
    ids = []
    for i in 1:number_of_instances
        instance = instances["instancesSet"]["item"][i]
        instance_id = instance["instanceId"]
        push!(ids, instance_id)
    end
    ids
end

function delete_instances()
    
end

#=
Sistema de Arquivo Compartilhado
=#
function create_efs()
    chars = ['a':'z'; 'A':'Z'; '0':'9']
    creation_token = join(chars[Random.rand(1:length(chars), 64)])
    Efs.create_file_system(creation_token)["FilesystemId"]
end

function delete_efs(id)
    Efs.delete_file_system(id)
end

