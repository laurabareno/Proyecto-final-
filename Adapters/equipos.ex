defmodule EquiposCSV do
  alias CsvUtil
  alias Equipo

  @path "equipos.csv"
  @header ["id","nombre","tema","participantes(|)","mentores(|)","estado"]

  #API
  def all, do: read_all()
  def get(id), do: all() |> Enum.find(&(&1.id == id))

  def listar_activos() do
  equipos = all() |> Enum.filter(&(&1.estado == :activo))
  {:ok, equipos}
 end

  def crear_por_tema(nombre, tema) do
    equipos = all()
    id = if equipos == [], do: 1, else: Enum.max_by(equipos, & &1.id).id + 1
    e = %Equipo{id: id, nombre: nombre, tema: tema, participantes: [], mentores: [], estado: :activo}
    upsert(e)
  end

  def agregar_miembro(equipo_id, user_id) do
    case get(equipo_id) do
      nil -> {:error, :equipo_no_existe}
      %Equipo{} = e ->
        nuevos = Enum.uniq(e.participantes ++ [user_id])
        upsert(%{e | participantes: nuevos})
    end
  end

  def upsert(%Equipo{} = e) do
    equipos = all() |> Enum.reject(&(&1.id == e.id)) |> Kernel.++([e])
    write!(equipos)
    {:ok, e}
  end


end
