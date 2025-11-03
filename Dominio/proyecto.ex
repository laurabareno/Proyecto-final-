defmodule Proyecto do

  defstruct id: 0,
            nombre: "",
            descripcion: "",
            tema: "",
            equipo_id: nil,
            mentor_id: nil,
            participantes_ids: [],
            estado: :propuesto

  @estados [:propuesto, :en_progreso, :finalizado, :descartado]


  def crear(nombre, descripcion, tema, opts \\ [])
      when is_binary(nombre) and is_binary(descripcion) and is_binary(tema) do
    %__MODULE__{
      id: Keyword.get(opts, :id, System.unique_integer([:positive])),
      nombre: nombre,
      descripcion: descripcion,
      tema: tema,
      equipo_id: Keyword.get(opts, :equipo_id),
      mentor_id: Keyword.get(opts, :mentor_id),
      participantes_ids: Keyword.get(opts, :participantes_ids, []),
      estado: Keyword.get(opts, :estado, :propuesto)
    }
  end


  def crear_desde_consola() do
    nombre      = IO.gets("Nombre del proyecto: ") |> String.trim()
    descripcion = IO.gets("Descripción breve: ")   |> String.trim()
    tema        = IO.gets("Tema/Categoría: ")      |> String.trim()
    crear(nombre, descripcion, tema)
  end


  def cambiar_estado(%__MODULE__{} = p, nuevo) when nuevo in @estados, do: %{p | estado: nuevo}
  def asignar_equipo(%__MODULE__{} = p, equipo_id) when is_integer(equipo_id) and equipo_id > 0, do: %{p | equipo_id: equipo_id}
  def asignar_mentor(%__MODULE__{} = p, mentor_id) when is_integer(mentor_id) and mentor_id > 0, do: %{p | mentor_id: mentor_id}
end
