defmodule ProyectosCSV do
  @path "proyectos.csv"
  @header ["id","nombre","descripcion","tema","equipo_id","mentor_id","participantes_ids(|)","estado"]

  # ---------- API ----------
  def all(), do: read_all()

  def get(id) when is_integer(id),
    do: all() |> Enum.find(&(&1.id == id))

  def crear_idea(%Proyecto{} = p) do
    upsert(p)
  end

  def upsert(%Proyecto{} = p) do
    lista =
      all()
      |> Enum.reject(&(&1.id == p.id))
      |> Kernel.++([p])

    write!(lista)
    {:ok, p}
  end

  def delete(id) when is_integer(id) do
    lista = all() |> Enum.reject(&(&1.id == id))
    write!(lista)
    :ok
  end

  def listar_por_estado(estado_atom) when is_atom(estado_atom),
    do: all() |> Enum.filter(&(&1.estado == estado_atom))

  def listar_por_tema(tema_str) when is_binary(tema_str),
    do: all() |> Enum.filter(&(String.downcase(&1.tema) == String.downcase(tema_str)))
end 
