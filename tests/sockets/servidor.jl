using Sockets

function servidor_tcp(porta)
  server = listen(porta)

  println("Servidor TCP rodando na porta $porta")

  while true
    sock = accept(server)

    @async begin
      println("Cliente conectado: $(getpeername(sock))")

      try
        while isopen(sock)
          dados_recebidos = readavailable(sock)
          if !isempty(dados_recebidos)
            mensagem = String(dados_recebidos)
            println("Recebido: $mensagem")

            # Envia uma resposta para o cliente (usando write)
            write(sock, "Servidor: Mensagem recebida com sucesso!\n") 
          end
          sleep(0.01)
        end
      catch e
        println("Erro na conexão com o cliente: $e")
      finally
        close(sock)
        println("Cliente desconectado: $(getpeername(sock))")
      end
    end
  end
end

servidor_tcp(8080)
