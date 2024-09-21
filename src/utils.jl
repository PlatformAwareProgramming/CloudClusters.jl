chars = ['a':'z'; 'A':'Z']
create_sym(n) = join(chars[Random.rand(1:length(chars), n)]) |> Symbol

function fetchtype(strt)
    
    stra = split(strt, ".")
    m = @__MODULE__
    for s in stra 
        m = getfield(m, Symbol(s))
    end
    m
end
