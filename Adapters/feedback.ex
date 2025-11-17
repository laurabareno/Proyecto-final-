defmodule FeedbackCSV do
  @moduledoc "Persistencia CSV de feedback formal (comentarios, revisiones, puntajes)."

  @path Path.expand("../feedback.csv", __DIR__)
  @header ["id","equipo_id","proyecto_id","autor_id","tipo","titulo","detalle","puntaje","tags(|)","acciones(|)","estado_accion","timestamp"]

  alias CsvUtil
  alias Feedback

  # API
  def all(), do: read_all()

  def get(id) when is_integer(id),
    do: all() |> Enum.find(&(&1.id == id))

  def append(%Feedback{} = f) do
    lista =
      all()
      |> Enum.reject(&(&1.id == f.id))
      |> Kernel.++([f])

    write!(lista)
    {:ok, f}
  end

  def upsert(%Feedback{} = f), do: append(f)

  def update(id, nuevos_datos) when is_integer(id) and is_map(nuevos_datos) do
  case get(id) do
    nil ->
      {:error, :feedback_no_existe}

    %Feedback{} = fb ->
      actualizado = Map.merge(fb, nuevos_datos)
      upsert(actualizado)
  end
end

  def delete(id) when is_integer(id) do
    lista = all() |> Enum.reject(&(&1.id == id))
    write!(lista)
    :ok
  end

  def listar_por_equipo(equipo_id) when is_integer(equipo_id),
    do: all() |> Enum.filter(&(&1.equipo_id == equipo_id))

  def listar_por_proyecto(proyecto_id) when is_integer(proyecto_id),
    do: all() |> Enum.filter(&(&1.proyecto_id == proyecto_id))

  # ---------- Internos ----------

  defp ensure_header!() do
    unless File.exists?(@path) do
      :ok = CsvUtil.atomic_write(@path, Enum.join(@header, ",") <> CsvUtil.newline())
    end
  end

  #Limpieza de valores antes de escribi
  defp sanitize_value(nil), do: ""
  defp sanitize_value("nil"), do: ""
  defp sanitize_value(value) when is_integer(value), do: Integer.to_string(value)
  defp sanitize_value(value) when is_binary(value), do: String.trim(value)
  defp sanitize_value(value) when is_list(value), do: Enum.join(value, "|")
  defp sanitize_value(value), do: to_string(value)

  # Escritura
  defp write!(lista) do
    ensure_header!()

    rows =
      lista
      |> Enum.map(fn %Feedback{
                        id: id, equipo_id: eq, proyecto_id: pr, autor_id: au,
                        tipo: tipo, titulo: ti, detalle: de, puntaje: pu,
                        tags: tags, acciones: acciones, estado_accion: ea,
                        timestamp: ts
                      } ->
        [
          sanitize_value(id),
          sanitize_value(eq),
          sanitize_value(pr),
          sanitize_value(au),
          sanitize_value(Atom.to_string(tipo)),
          sanitize_value(ti),
          sanitize_value(de),
          sanitize_value(pu),
          sanitize_value(tags),
          sanitize_value(acciones),
          sanitize_value(Atom.to_string(ea)),
          sanitize_value(ts_to_iso(ts))
        ]
        |> Enum.join(",")
      end)
      |> Enum.join(CsvUtil.newline())

    content = Enum.join(@header, ",") <> CsvUtil.newline() <> rows <> CsvUtil.newline()
    :ok = CsvUtil.atomic_write(@path, content)
  end

  # Lectura
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
    cols = cols ++ List.duplicate("", max(0, 12 - length(cols)))
    [id_s, eq_s, pr_s, au_s, tipo_s, ti, de, pu_s, tags_s, acc_s, ea_s, ts] = cols

    %Feedback{
      id: parse_int(id_s),
      equipo_id: parse_int_opt(eq_s),
      proyecto_id: parse_int_opt(pr_s),
      autor_id: parse_int_opt(au_s),
      tipo: safe_to_atom(tipo_s, :comentario),
      titulo: ti,
      detalle: de,
      puntaje: parse_int_opt(pu_s),
      tags: if(tags_s == "", do: [], else: String.split(tags_s, "|", trim: true)),
      acciones: if(acc_s == "", do: [], else: String.split(acc_s, "|", trim: true)),
      estado_accion: safe_to_atom(ea_s, :pendiente),
      timestamp: ts
    }
  end

  defp parse_int(str) do
    case Integer.parse(String.trim(str || "")) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp parse_int_opt(str) do
    case String.trim(str || "") do
      "" -> nil
      s ->
        case Integer.parse(s) do
          {n, _} -> n
          :error -> nil
        end
    end
  end

  def actualizar(id, nuevos_datos) when is_integer(id) and is_map(nuevos_datos) do
  case FeedbackCSV.get(id) do
    nil ->
      {:error, :feedback_no_existe}

    %Feedback{} = fb ->
      actualizado = Map.merge(fb, nuevos_datos)
      FeedbackCSV.upsert(actualizado)
  end
end


  defp safe_to_atom("", default), do: default
  defp safe_to_atom(nil, default), do: default
  defp safe_to_atom(s, _default), do: String.to_atom(String.trim(s))

  defp ts_to_iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp ts_to_iso(iso) when is_binary(iso), do: iso
  defp ts_to_iso(nil), do: ""
end
