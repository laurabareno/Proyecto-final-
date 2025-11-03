defmodule Feedback do

  @tipos [:comentario, :revision, :puntaje]
  @estados_accion [:pendiente, :en_progreso, :resuelto]

  defstruct id: 0,
            equipo_id: nil,
            proyecto_id: nil,
            autor_id: nil,
            tipo: :comentario,
            titulo: "",
            detalle: "",
            puntaje: nil,
            tags: [],
            acciones: [],
            estado_accion: :pendiente,
            timestamp: nil

  @type t :: %__MODULE__{}

  def crear(equipo_id, autor_id, attrs \\ []) when is_integer(equipo_id) and is_integer(autor_id) do
    tipo = Keyword.get(attrs, :tipo, :comentario)
    validar_tipo!(tipo)

    puntaje = Keyword.get(attrs, :puntaje)
    if tipo == :puntaje and not is_integer(puntaje) do
      raise ArgumentError, "Cuando tipo = :puntaje debes enviar :puntaje como entero (0..100)"
    end

    %__MODULE__{
      id: Keyword.get(attrs, :id, System.unique_integer([:positive])),
      equipo_id: equipo_id,
      proyecto_id: Keyword.get(attrs, :proyecto_id),
      autor_id: autor_id,
      tipo: tipo,
      titulo: Keyword.get(attrs, :titulo, ""),
      detalle: Keyword.get(attrs, :detalle, ""),
      puntaje: puntaje,
      tags: Keyword.get(attrs, :tags, []),
      acciones: Keyword.get(attrs, :acciones, []),
      estado_accion: Keyword.get(attrs, :estado_accion, :pendiente),
      timestamp: Keyword.get(attrs, :timestamp, DateTime.utc_now())
    }
  end

  def comentario(equipo_id, autor_id, titulo, detalle, opts \\ []),
    do: crear(equipo_id, autor_id, Keyword.merge([tipo: :comentario, titulo: titulo, detalle: detalle], opts))

  def revision(equipo_id, autor_id, titulo, detalle, acciones \\ [], opts \\ []),
    do: crear(equipo_id, autor_id, Keyword.merge([tipo: :revision, titulo: titulo, detalle: detalle, acciones: acciones], opts))

  def puntaje(equipo_id, autor_id, titulo, detalle, puntaje, opts \\ []),
    do: crear(equipo_id, autor_id, Keyword.merge([tipo: :puntaje, titulo: titulo, detalle: detalle, puntaje: puntaje], opts))


  def set_estado_accion(%__MODULE__{} = f, nuevo) when nuevo in @estados_accion, do: %{f | estado_accion: nuevo}
  def agregar_accion(%__MODULE__{} = f, accion) when is_binary(accion), do: %{f | acciones: f.acciones ++ [accion]}

  defp validar_tipo!(t) when t in @tipos, do: :ok
  defp validar_tipo!(t), do: raise(ArgumentError, "Tipo inválido #{inspect(t)}. Usa: #{@tipos |> Enum.join(", ")}")


end
