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

function try_run(command)

    successfull = false
    while !successfull
        try
            run(command)
            successfull = true
        catch
            @error "failed: $command - trying again"
            sleep(0.5)
        end        
    end

end