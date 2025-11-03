defmodule GestionEquipos do
  def registrar_usuario_y_asignar(%Usuario{} = u, equipo_id \\ nil) do
    with {:ok, _} <- UsuariosCSV.upsert(u),
         :ok <- maybe_asignar(u.id, equipo_id) do
      {:ok, u}
    end
  end

  defp maybe_asignar(_user_id, nil), do: :ok
  defp maybe_asignar(user_id, equipo_id) do
    case EquiposCSV.get(equipo_id) do
      nil -> {:error, :equipo_no_existe}
      %Equipo{estado: "inactivo"} -> {:error, :equipo_inactivo}
      _ -> EquiposCSV.agregar_miembro(equipo_id, user_id) |> then(fn {:ok, _} -> :ok; other -> other end)
    end
  end

  def crear_equipo_por_tema(nombre, tema) do
    EquiposCSV.crear_por_tema(nombre, tema)
  end

  def crear_equipo_por_tema(_, _), do: {:error, :parametros_invalidos}

 def listar_equipos_activos() do
  case EquiposCSV.listar_activos() do
    {:ok, equipos} when length(equipos) > 0 ->
      {:ok, equipos}

    {:ok, []} ->
      {:error, "No hay equipos activos"}

    {:error, razon} ->
      {:error, "No se pudieron obtener los equipos: #{razon}"}

    _ ->
      {:error, "Error al listar equipos activos"}
  end
end


end
