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
            sleep(2)
        end        
    end

end

last_exceptions = Ref{Vector{Any}}(Vector{Any}())

function save_exception_details()

    empty!(last_exceptions[])
    for (exc, bt) in current_exceptions()
        push!(last_exceptions[],(exc, bt))
    end

end

function show_exceptions()

    for (exc, bt) in last_exceptions[]
        showerror(stdout, exc, bt)
        println(stdout)
    end

end

file_extension(file::String) = file[findlast(==('.'), file)+1:end]