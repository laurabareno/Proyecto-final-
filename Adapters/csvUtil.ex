defmodule CsvUtil do
  @newline "\r\n"
  def newline, do: @newline

  # Escapa comillas y envuelve si hay caracteres problemáticos
  def escape(s) when is_binary(s) do
    needs = String.contains?(s, [",","\"","\n","\r"])
    esc   = String.replace(s, "\"", "\"\"")
    if needs, do: "\"#{esc}\"", else: esc
  end
  def escape(i) when is_integer(i), do: Integer.to_string(i)
  def escape(a) when is_atom(a),    do: Atom.to_string(a)
  def escape(list) when is_list(list),
    do: list |> Enum.map(&escape/1) |> Enum.join("|")
  def escape(nil), do: ""

  def atomic_write(path, content) do
    tmp = path <> ".tmp"
    with :ok <- File.write(tmp, content),
         :ok <- File.rename(tmp, path) do
      :ok
    else
      err -> _ = File.rm(tmp); err
    end
  end

  # Split CSV mínimo con comillas dobles
  def split_csv_minimal(line), do: do_split(line, [], "", :normal)
  defp do_split(<<>>, acc, cur, _), do: Enum.reverse([cur | acc])
  defp do_split(<<","::binary, rest::binary>>, acc, cur, :normal),
    do: do_split(rest, [cur | acc], "", :normal)
  defp do_split(<<"\""::binary, rest::binary>>, acc, cur, :normal),
    do: do_split(rest, acc, cur, :quoted)
  defp do_split(<<ch::utf8, rest::binary>>, acc, cur, :normal),
    do: do_split(rest, acc, cur <> <<ch::utf8>>, :normal)
  defp do_split(<<"\"\""::binary, rest::binary>>, acc, cur, :quoted),
    do: do_split(rest, acc, cur <> "\"", :quoted)
  defp do_split(<<"\""::binary, rest::binary>>, acc, cur, :quoted),
    do: do_split(rest, acc, cur, :normal)
  defp do_split(<<ch::utf8, rest::binary>>, acc, cur, :quoted),
    do: do_split(rest, acc, cur <> <<ch::utf8>>, :quoted)
end
