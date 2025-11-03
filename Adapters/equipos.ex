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

  # Internos
  defp ensure_header! do
    unless File.exists?(@path) do
      CsvUtil.atomic_write(@path, Enum.join(@header, ",") <> CsvUtil.newline())
    end
  end

  defp read_all do
    ensure_header!()

    @path
    |> File.stream!([], :line)
    |> Stream.map(&String.trim_trailing(&1, "\n"))
    |> Stream.map(&String.trim_trailing(&1, "\r"))
    |> Enum.to_list()
    |> case do
      [] -> []
      [_header | rows] ->
        rows
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&parse_row/1)
    end
  end

  defp parse_row(line) do

    cols = CsvUtil.split_csv_minimal(line)
    cols = cols ++ List.duplicate("", max(0, 6 - length(cols)))
    [id_s, nombre, tema, part_s, ment_s, estado_s] = cols

    participantes =
      if part_s == "", do: [], else: String.split(part_s, "|", trim: true) |> Enum.map(&String.to_integer/1)

    mentores =
      if ment_s == "", do: [], else: String.split(ment_s, "|", trim: true) |> Enum.map(&String.to_integer/1)

    %Equipo{
      id: String.to_integer(id_s),
      nombre: nombre,
      tema: tema,
      participantes: participantes,
      mentores: mentores,
      estado: safe_to_atom(estado_s)
    }
  end

  defp write!(equipos) do
    ensure_header!()

    rows =
      equipos
      |> Enum.map(fn %Equipo{id: id, nombre: n, tema: t, participantes: p, mentores: m, estado: est} ->
        [
          CsvUtil.escape(id),
          CsvUtil.escape(n),
          CsvUtil.escape(t),
          CsvUtil.escape(p),                         # lista -> "1|2|3"
          CsvUtil.escape(m),                         # lista -> "..."
          CsvUtil.escape(Atom.to_string(est))        # átomo -> string para CSV
        ]
        |> Enum.join(",")
      end)
      |> Enum.join(CsvUtil.newline())

    content = Enum.join(@header, ",") <> CsvUtil.newline() <> rows <> CsvUtil.newline()
    :ok = CsvUtil.atomic_write(@path, content)
  end

  defp safe_to_atom(""), do: :activo
  defp safe_to_atom(s), do: String.trim(s) |> String.downcase() |> String.to_atom()

  def update(id, nuevos_datos) when is_integer(id) and is_map(nuevos_datos) do
  case get(id) do
    nil -> {:error, :equipo_no_existe}
    %Equipo{} = e ->
      actualizado = Map.merge(e, nuevos_datos)
      upsert(actualizado)
  end
end

def delete(id) when is_integer(id) do
  lista = all() |> Enum.reject(&(&1.id == id))
  write!(lista)
  :ok
end


end
