defmodule NodoChatServidor do
  @nombre_servicio_local :servicio_chat

  def main() do


    IO.puts("SERVIDOR: iniciando…")
    registrar_servicio(@nombre_servicio_local)

    estado_inicial = %{subs: %{}, total_msgs: 0, next_id: 0}

    procesar_mensajes(estado_inicial)
  end

  defp registrar_servicio(nombre), do: Process.register(self(), nombre)

  defp procesar_mensajes(estado) do
    receive do
      {origen, {:join, canal}} ->
        estado = add_sub(estado, canal, origen)
        send(origen, {:joined, canal})
        procesar_mensajes(estado)

      {origen, {:leave, canal}} ->
        estado = remove_sub(estado, canal, origen)
        send(origen, {:left, canal})
        procesar_mensajes(estado)

      {origen, {:send, canal, equipo_id, remitente_id, texto}} ->
        msg = %Mensaje{
          id: estado.next_id,
          canal: canal,
          equipo_id: equipo_id,
          remitente_id: remitente_id,
          contenido: texto,
          timestamp: DateTime.utc_now() |> DateTime.truncate(:millisecond)
        }

        persist_res =
          try do
            MensajesCSV.append(msg)
          catch
            kind, reason ->
              {:error, {kind, reason}}
          end

        case persist_res do
          :ok -> :ok
          {:ok, _} -> :ok
          {:error, reason} ->
            IO.puts("SERVIDOR: persistencia falló #{inspect(reason)}")
            :ok
          other ->
            IO.puts("SERVIDOR: persistencia devolvió inesperado #{inspect(other)}")
            :ok
        end

        IO.puts("[#{inspect(msg.canal)}][equipo #{msg.equipo_id}] u#{msg.remitente_id}: #{msg.contenido}")
        send(origen, {:ok, msg})
        broadcast(estado, msg.canal, {:chat, msg}, exclude: origen)

        estado2 = %{estado | total_msgs: estado.total_msgs + 1, next_id: estado.next_id + 1}
        procesar_mensajes(estado2)

      {origen, :fin} ->
        send(origen, :fin)
        procesar_mensajes(estado)

      otro ->
        IO.puts("SERVIDOR: mensaje desconocido #{inspect(otro)}")
        procesar_mensajes(estado)
    end
  end

  defp add_sub(estado, canal, destino) do
    subs = Map.update(estado.subs, canal, MapSet.new([destino]), &MapSet.put(&1, destino))
    %{estado | subs: subs}
  end

  defp remove_sub(estado, canal, destino) do
    subs = Map.update(estado.subs, canal, MapSet.new(), &MapSet.delete(&1, destino))
    %{estado | subs: subs}
  end

  defp broadcast(estado, canal, payload, opts) do
    exclude = Keyword.get(opts, :exclude, nil)
    for dest <- Map.get(estado.subs, canal, MapSet.new()) do
      if dest != exclude, do: send(dest, payload)
    end
    :ok
  end
end

NodoChatServidor.main()
