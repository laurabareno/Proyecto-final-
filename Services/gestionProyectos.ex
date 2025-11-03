defmodule GestionProyectos do

  def registrar_idea(nombre, descripcion, tema, opts \\ []) do
    p = Proyecto.crear(nombre, descripcion, tema, opts)
    ProyectosCSV.crear_idea(p)
  end


  def asignar_equipo(proyecto_id, equipo_id) do
    with %Proyecto{} = p <- ProyectosCSV.get(proyecto_id) || {:error, :proyecto_no_existe},
         %Equipo{}   <- EquiposCSV.get(equipo_id) || {:error, :equipo_no_existe},
         p2          <- Proyecto.asignar_equipo(p, equipo_id),
         {:ok, _}    <- upsert(p2) do
      {:ok, p2}
    end
  end


  def asignar_mentor(proyecto_id, mentor_id) do
    with %Proyecto{} = p <- ProyectosCSV.get(proyecto_id) || {:error, :proyecto_no_existe},
         %Usuario{rol: :mentor} <- UsuariosCSV.get(mentor_id) || {:error, :mentor_no_existe_o_invalido},
         p2 <- Proyecto.asignar_mentor(p, mentor_id),
         {:ok, _} <- upsert(p2) do
      {:ok, p2}
    end
  end


  @permitidos [:propuesto, :en_progreso, :finalizado, :descartado]
  def cambiar_estado(proyecto_id, nuevo) when nuevo in @permitidos do
    with %Proyecto{} = p <- ProyectosCSV.get(proyecto_id) || {:error, :proyecto_no_existe},
         p2 <- Proyecto.cambiar_estado(p, nuevo),
         {:ok, _} <- upsert(p2) do
      {:ok, p2}
    end
  end


  def registrar_avance(proyecto_id, attrs) when is_map(attrs) do
    case ProyectosCSV.get(proyecto_id) do
      nil -> {:error, :proyecto_no_existe}
      %Proyecto{} = p ->
        p2 =
          case Map.get(attrs, :estado) do
            nil -> p
            nuevo -> Proyecto.cambiar_estado(p, nuevo)
          end


        ProyectosCSV.upsert(p2)
    end
  end


  def listar_por_estado(estado), do: ProyectosCSV.listar_por_estado(estado)
  def listar_por_tema(tema), do: ProyectosCSV.listar_por_tema(tema)


  defp upsert(%Proyecto{} = p), do: ProyectosCSV.upsert(p)
end
