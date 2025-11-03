defmodule FeedbackService do

  def crear(equipo_id, autor_id, attrs \\ []) do
    IO.puts(" Iniciando creación de feedback...")
    IO.inspect(equipo_id, label: "→ ID equipo")
    IO.inspect(autor_id, label: "→ ID autor")

    equipo = EquiposCSV.get(equipo_id)
    autor = UsuariosCSV.get(autor_id)

    IO.inspect(equipo, label: "→ Equipo obtenido")
    IO.inspect(autor, label: "→ Autor obtenido")


    rol_autor = normalizar_rol(Map.get(autor || %{}, :rol))
    IO.inspect(rol_autor, label: "→ Rol normalizado")

    cond do
      equipo == nil ->
        IO.puts(" Error: el equipo no existe.")
        {:error, :equipo_no_existe}

      autor == nil ->
        IO.puts(" Error: el autor no existe.")
        {:error, :autor_no_existe}

      rol_autor != :mentor ->
        IO.puts(" Error: el autor no es un mentor (rol actual: #{inspect(rol_autor)}).")
        {:error, :autor_no_es_mentor}

      true ->
        IO.puts(" Validaciones correctas. Creando feedback...")
        fb = Feedback.crear(equipo_id, autor_id, attrs)
        IO.inspect(fb, label: "→ Feedback generado")

        case FeedbackCSV.append(fb) do
          {:ok, _} ->
            IO.puts(" Feedback guardado correctamente.")
            {:ok, fb}

          other ->
            IO.puts(" Error al guardar feedback: #{inspect(other)}")
            other
        end
    end
  rescue
    e ->
      IO.puts(" Error inesperado en FeedbackService.crear/3:")
      IO.inspect(e)
      {:error, e}
  end

  def listar_por_equipo(equipo_id), do: FeedbackCSV.listar_por_equipo(equipo_id)
  def listar_por_proyecto(proyecto_id), do: FeedbackCSV.listar_por_proyecto(proyecto_id)

  def resolver_accion(feedback_id) do
    case FeedbackCSV.get(feedback_id) do
      nil -> {:error, :feedback_no_existe}
      %Feedback{} = f ->
        f2 = Feedback.set_estado_accion(f, :resuelto)
        FeedbackCSV.upsert(f2)
    end
  end


  def actualizar(id, nuevos_datos) when is_integer(id) and is_map(nuevos_datos) do
    case FeedbackCSV.get(id) do
      nil ->
        IO.puts(" No se encontró feedback con ID #{id}.")
        {:error, :feedback_no_existe}

      %Feedback{} = fb ->
        actualizado = Map.merge(fb, nuevos_datos)
        FeedbackCSV.upsert(actualizado)
        IO.puts(" Feedback actualizado correctamente.")
        {:ok, actualizado}
    end
  end


  defp normalizar_rol(nil), do: nil
  defp normalizar_rol(rol) when is_atom(rol), do: rol
  defp normalizar_rol(rol) when is_binary(rol), do: String.to_atom(String.downcase(rol))
end
