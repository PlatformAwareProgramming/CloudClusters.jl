chars = ['a':'z'; 'A':'Z']
create_sym(n) = join(chars[Random.rand(1:length(chars), n)]) |> Symbol
