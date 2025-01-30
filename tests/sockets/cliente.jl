using Sockets

function cliente_tcp(ip, porta)
  try
    sock = connect(ip, porta)

    println("Conectado ao servidor em $ip:$porta")

    while isopen(sock)
      print("Digite uma mensagem (ou 'sair' para desconectar): ")
      mensagem = readline()

      if mensagem == "sair"
        break
      end

      # Envia a mensagem para o servidor (usando write)
      write(sock, mensagem * "\n")

      dados_recebidos = readavailable(sock)
      if !isempty(dados_recebidos)
        resposta = String(dados_recebidos)
        println("Resposta do servidor: $resposta")
      end
    end

    println("Desconectado do servidor.")
    close(sock)

  catch e
    println("Erro ao conectar ou comunicar com o servidor: $e")
  end
end

ip_servidor = "127.0.0.1" 
porta_servidor = 8080

cliente_tcp(ip_servidor, porta_servidor)
