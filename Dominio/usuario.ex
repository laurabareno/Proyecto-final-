defmodule Usuario do
  defstruct nombre: "", id: 0, correo: "", rol: ""   # rol: "participante" | "mentor"

  def crear(nombre, id, correo, rol) when is_integer(id) do
    %Usuario{nombre: nombre, id: id, correo: correo, rol: rol}
  end

  def crear_desde_consola() do
    nombre = IO.gets("Ingresa el nombre: ") |> String.trim()

    id =
      IO.gets("Ingresa número id (entero): ")
      |> String.trim()
      |> String.to_integer()

    correo = IO.gets("Ingresa tu correo: ") |> String.trim()
    rol    = IO.gets("Ingresa tu rol en la hackatón (participante/mentor): ") |> String.trim()

    crear(nombre, id, correo, rol)
  rescue
    ArgumentError ->
      IO.puts(" ID inválido. Intenta de nuevo.\n")
      crear_desde_consola()
  end
end
