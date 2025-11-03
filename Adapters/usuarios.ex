defmodule UsuariosCSV do

  alias CsvUtil
  alias Usuario

  @path "usuarios.csv"
  @header ["id", "nombre", "correo", "rol"]

  # UTILIDAD
  defp ensure_header!() do
    unless File.exists?(@path) do
      CsvUtil.atomic_write(@path, Enum.join(@header, ",") <> CsvUtil.newline())
    end
  end

  # LECTURA
  def all() do
    ensure_header!()

    @path
    |> File.read!()
    |> String.split(CsvUtil.newline(), trim: true)
    |> Enum.drop(1)
    |> Enum.map(&parse_row/1)
  end

  defp parse_row(line) do
    [id, nombre, correo, rol] = String.split(line, ",")
    %Usuario{
      id: String.to_integer(id),
      nombre: nombre,
      correo: correo,
      rol: String.to_atom(rol)
    }
  end

  def get(id), do: all() |> Enum.find(&(&1.id == id))

  # ESCRITURA
  defp write!(usuarios) do
    ensure_header!()
    contenido =
      [Enum.join(@header, ",")] ++
        Enum.map(usuarios, fn u ->
          "#{u.id},#{u.nombre},#{u.correo},#{Atom.to_string(u.rol)}"
        end)

    CsvUtil.atomic_write(@path, Enum.join(contenido, CsvUtil.newline()) <> CsvUtil.newline())
  end

  # OPERACIONES CRUD

  # Insertar o actualizar usuario
  def upsert(%Usuario{} = u) do
  ensure_header!()

  users =
    all()
    |> Enum.reject(&(&1.id == u.id))
    |> Kernel.++([u])

  content =
    [Enum.join(@header, ",")] ++
      Enum.map(users, fn x ->
        rol_str =
          case x.rol do
            r when is_atom(r) -> Atom.to_string(r)
            r when is_binary(r) -> r
            _ -> "desconocido"
          end

        "#{x.id},#{x.nombre},#{x.correo},#{rol_str}"
      end)

  CsvUtil.atomic_write(@path, Enum.join(content, CsvUtil.newline()) <> CsvUtil.newline())
  {:ok, u}
end


  # Actualizar usuario
  def update(id, nuevos_campos) when is_integer(id) and is_map(nuevos_campos) do
    case get(id) do
      nil ->
        {:error, :usuario_no_encontrado}

      %Usuario{} = usuario ->
        actualizado = Map.merge(usuario, nuevos_campos)
        upsert(actualizado)
    end
  end

  # Eliminar usuario
  def delete(id) when is_integer(id) do
    lista = all() |> Enum.reject(&(&1.id == id))
    write!(lista)
    :ok
  end
end
