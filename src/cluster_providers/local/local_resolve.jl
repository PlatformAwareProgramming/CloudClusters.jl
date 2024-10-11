
abstract type Localhost <: OnPremises end

# fetch Platorm.toml data from PlatormAware.jl
instance_info = PlatformAware.state.platform_feature_all
instance_type = "localhost"
instance_info[:node_provider] = Localhost

parameters, instance_feature_table = fetch_features(instance_info, keytype = Symbol)

instance_type_table[instance_type] = instance_feature_table

resolve_decl = Expr(:function, Expr(:call, parameters...), Expr(:block, Expr(:return, (instance_type, Localhost))))
@info resolve_decl
eval(resolve_decl)


