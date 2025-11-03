defmodule MensajesCSV do
 @path Path.expand("../mensajes.csv", __DIR__)
  @header ["id","contenido","remitente_id","equipo_id","canal","timestamp"]

  # API
  def all(), do: read_all()

  def get(id) when is_integer(id),
    do: all() |> Enum.find(&(&1.id == id))

  def append(%Mensaje{} = m) do
    lista =
      all()
      |> Enum.reject(&(&1.id == m.id))
      |> Kernel.++([m])

    write!(lista)
    {:ok, m}
  end

  def upsert(%Mensaje{} = m), do: append(m)

  def delete(id) when is_integer(id) do
    lista = all() |> Enum.reject(&(&1.id == id))
    write!(lista)
    :ok
  end

  def listar_por_canal(canal) when is_binary(canal),
    do: all() |> Enum.filter(&(String.downcase(&1.canal) == String.downcase(canal)))

  def listar_por_equipo(equipo_id) when is_integer(equipo_id),
    do: all() |> Enum.filter(&(&1.equipo_id == equipo_id))

  #Internos
  defp ensure_header!() do
    unless File.exists?(@path) do
      :ok = CsvUtil.atomic_write(@path, Enum.join(@header, ",") <> CsvUtil.newline())
    end
  end

  defp sanitize_value(nil), do: ""
  defp sanitize_value("nil"), do: ""
  defp sanitize_value(value) when is_integer(value), do: Integer.to_string(value)
  defp sanitize_value(value) when is_binary(value), do: String.trim(value)
  defp sanitize_value(value), do: to_string(value)

  defp write!(lista) do
    ensure_header!()
    rows =
      lista
      |> Enum.map(fn %Mensaje{
                        id: id, contenido: c, remitente_id: r,
                        equipo_id: eq, canal: canal, timestamp: ts
                      } ->
        [
          sanitize_value(id),
          sanitize_value(c),
          sanitize_value(r),
          sanitize_value(eq),
          sanitize_value(canal),
          sanitize_value(ts_to_iso(ts))
        ]
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
      |> Stream.map(&String.trim/1)
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
  cols =
    line
    |> CsvUtil.split_csv_minimal()
    |> Enum.map(fn v ->
      v
      |> to_string()
      |> String.trim()
      |> String.replace(~r/\s+/, "")
      |> case do
        "" -> nil
        "nil" -> nil
        other -> other
      end
    end)
    |> then(&(&1 ++ List.duplicate(nil, max(0, 6 - length(&1)))))

  [id_s, c, r_s, eq_s, canal, ts] = cols

  %Mensaje{
    id: safe_int(id_s),
    contenido: c || "",
    remitente_id: safe_int(r_s),
    equipo_id: safe_int(eq_s),
    canal: canal || "",
    timestamp: ts || ""
  }
end

#versión segura
defp safe_int(nil), do: nil
defp safe_int(""), do: nil
defp safe_int("nil"), do: nil
defp safe_int(str) when is_binary(str) do
  case Integer.parse(str) do
    {num, _} -> num
    :error -> nil
  end
end
defp safe_int(num) when is_integer(num), do: num



  defp parse_int(str) do
    cond do
      is_nil(str) -> nil
      str in ["", "nil"] -> nil
      true ->
        case Integer.parse(str) do
          {num, _} -> num
          :error -> nil
        end
    end
  end

  defp ts_to_iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp ts_to_iso(iso) when is_binary(iso), do: iso
  defp ts_to_iso(nil), do: ""

end
