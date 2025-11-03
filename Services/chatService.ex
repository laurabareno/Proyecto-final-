defmodule ChatService do

  def enviar(contenido, remitente_id, opts \\ []) do
    with %Usuario{} <- UsuariosCSV.get(remitente_id) || {:error, :remitente_no_existe},
         :ok <- validar_destino(opts) do
      msg = Mensaje.crear(contenido, remitente_id, opts)
      MensajesCSV.append(msg)
    end
  end

  def listar_general(), do: MensajesCSV.listar_por_canal("general")
  def listar_equipo(equipo_id), do: MensajesCSV.listar_por_equipo(equipo_id)

  defp validar_destino(opts) do
    case Keyword.get(opts, :canal, "general") do
      "equipo" ->
        case Keyword.get(opts, :equipo_id) do
          nil -> {:error, :equipo_id_requerido}
          id when is_integer(id) ->
            if EquiposCSV.get(id), do: :ok, else: {:error, :equipo_no_existe}
        end
      _ -> :ok
    end
  end
end
