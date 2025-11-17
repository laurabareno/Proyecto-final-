defmodule NodoChatCliente do
  @nombre_servicio_local :servicio_cliente
  @nodo_remoto :"nodoservidor@ASUS"
  @servicio_remoto {:servicio_chat, @nodo_remoto}
  @canal_por_defecto :general

  def main() do
    IO.puts("CLIENTE: iniciando…")
    registrar_servicio(@nombre_servicio_local)

    case Node.connect(@nodo_remoto) do
      true -> iniciar_chat()
      false -> IO.puts("No se pudo conectar con el nodo servidor")
    end
  end

  defp registrar_servicio(nombre), do: Process.register(self(), nombre)
  defp servicio_local, do: {@nombre_servicio_local, node()}

  defp iniciar_chat() do
    enviar_mensaje({:join, @canal_por_defecto})
    IO.puts("Conectado al canal #{@canal_por_defecto}")

    spawn_link(fn -> recibir_respuestas() end)
    ciclo_envio()
  end

  defp ciclo_envio() do
    equipo_id = prompt("Tu equipo id: ") |> String.to_integer()
    remitente_id = prompt("Tu id de usuario: ") |> String.to_integer()

    IO.puts("Escribe tus mensajes (o 'fin' para salir):")

    Stream.repeatedly(fn -> IO.gets("> ") end)
    |> Stream.map(&String.trim(to_string(&1)))
    |> Enum.each(fn
      "fin" ->
        enviar_mensaje(:fin)
        IO.puts("Cerrando chat…")
        Process.exit(self(), :normal)

      texto when texto != "" ->
        enviar_mensaje({:send, @canal_por_defecto, equipo_id, remitente_id, texto})

      _ ->
        :ok
    end)
  end

  defp enviar_mensaje(payload), do: send(@servicio_remoto, {servicio_local(), payload})

  defp recibir_respuestas() do
    receive do
      {:joined, canal} ->
        IO.puts("Suscrito a #{inspect(canal)}")
        recibir_respuestas()

      {:chat, canal, equipo_id, remitente_id, texto} ->
        IO.puts("[#{inspect(canal)}][equipo #{equipo_id}] u#{remitente_id}: #{texto}")
        recibir_respuestas()

      :fin ->
        IO.puts(" Servidor confirmó :fin")
        :ok

      otro ->
        IO.puts("CLIENTE: mensaje desconocido #{inspect(otro)}")
        recibir_respuestas()
    end
  end

  defp prompt(msg), do: IO.gets(msg) |> to_string() |> String.trim()
end

NodoChatCliente.main()
