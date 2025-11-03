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

   # ---------- Internos ----------
  defp ensure_header!() do
    unless File.exists?(@path) do
      :ok = CsvUtil.atomic_write(@path, Enum.join(@header, ",") <> CsvUtil.newline())
    end
  end

  defp write!(lista) do
    ensure_header!()
    rows =
      lista
      |> Enum.map(fn %Proyecto{
                        id: id, nombre: n, descripcion: d, tema: t,
                        equipo_id: eq, mentor_id: me, participantes_ids: ps,
                        estado: e
                      } ->
        [CsvUtil.escape(id), CsvUtil.escape(n), CsvUtil.escape(d), CsvUtil.escape(t),
         CsvUtil.escape(eq), CsvUtil.escape(me), CsvUtil.escape(ps), CsvUtil.escape(e)]
        |> Enum.join(",")
      end)
      |> Enum.join(CsvUtil.newline())

    content = Enum.join(@header, ",") <> CsvUtil.newline() <> rows <> CsvUtil.newline()
    :ok = CsvUtil.atomic_write(@path, content)
  end

  defp read_all() do
    ensure_header!()
    lines =
      @path
      |> File.stream!([], :line)
      |> Stream.map(&String.trim_trailing(&1, "\n"))
      |> Stream.map(&String.trim_trailing(&1, "\r"))
      |> Enum.to_list()

    case lines do
      [] -> []
      [_header | rows] ->
        rows
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&parse_row/1)
    end
  end

  defp parse_row(line) do
    cols = CsvUtil.split_csv_minimal(line)
    cols = cols ++ List.duplicate("", max(0, 8 - length(cols)))
    [id_s, n, d, t, eq_s, me_s, ps_s, e_s] = cols

    {id, _} = Integer.parse(id_s)
    eq = parse_int_opt(eq_s)
    me = parse_int_opt(me_s)

    ps =
      if ps_s == "" do
        []
      else
        ps_s |> String.split("|", trim: true) |> Enum.map(&String.to_integer/1)
      end

    %Proyecto{
      id: id, nombre: n, descripcion: d, tema: t,
      equipo_id: eq, mentor_id: me, participantes_ids: ps,
      estado: String.to_atom(e_s)
    }
  end

  defp parse_int_opt(""), do: nil
  defp parse_int_opt(s) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> nil
    end
  end

  def update(id, nuevos_datos) when is_integer(id) and is_map(nuevos_datos) do
  case get(id) do
    nil -> {:error, :proyecto_no_existe}
    %Proyecto{} = p ->
      actualizado = Map.merge(p, nuevos_datos)
      upsert(actualizado)
  end
end

def delete(id) when is_integer(id) do
  lista = all() |> Enum.reject(&(&1.id == id))
  write!(lista)
  :ok
end
end
