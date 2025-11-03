defmodule Comandos do
  def start do
    IO.puts(" /help, /teams, /project <equipo>, /join <equipo>, /exit")
    loop()
  end

  defp loop do
    case IO.gets("> ") |> to_string() |> String.trim() |> String.split(" ", parts: 2) do
      ["/help"] ->
        IO.puts("/teams | /project <equipo> | /join <equipo> | /exit")
        loop()

      ["/teams"] ->
        EquiposCSV.all()
        |> Enum.each(fn e ->
          IO.puts("• [#{e.id}] #{e.nombre} (#{e.tema}) part: #{Enum.join(Enum.map(e.participantes,&to_string/1),", ")}")
        end)
        loop()

        ["/project", nombre_equipo] ->
        nombre_equipo = String.trim(nombre_equipo)

        case buscar_equipo_por_nombre(nombre_equipo) do
          nil ->
            IO.puts(" No se encontró ningún equipo con el nombre '#{nombre_equipo}'.")
            loop()

          %Equipo{id: eq_id, nombre: nombre} ->
            proyecto = ProyectosCSV.all() |> Enum.find(&(&1.equipo_id == eq_id))

            cond do
              proyecto == nil ->
                IO.puts(" El equipo '#{nombre}' no tiene ningún proyecto registrado.")
                loop()

              true ->
                usuarios = UsuariosCSV.all()
                mentor_nombre =
                  case Enum.find(usuarios, &(&1.id == proyecto.mentor_id)) do
                    nil -> "Sin mentor asignado"
                    %Usuario{nombre: n} -> "#{n} (ID: #{proyecto.mentor_id})"
                  end

                IO.puts("""
                ===== PROYECTO DEL EQUIPO '#{nombre}' =====
                ID Proyecto: #{proyecto.id}
                Nombre: #{proyecto.nombre}
                Descripción: #{proyecto.descripcion}
                Tema: #{proyecto.tema}
                Estado: #{proyecto.estado}
                Mentor: #{mentor_nombre}
                -------------------------------------------
                """)
                loop()
            end
        end


      ["/join", nombre] ->
        id = IO.gets("Tu ID de usuario: ") |> to_string() |> String.trim() |> String.to_integer()
        with %Usuario{} <- UsuariosCSV.get(id) || (IO.puts("Usuario no existe."); nil),
             %Equipo{} = eq <- buscar_equipo_por_nombre(nombre) || (IO.puts("Equipo no existe."); nil) do
          case EquiposCSV.agregar_miembro(eq.id, id) do
            {:ok, _} -> IO.puts("Te uniste a #{eq.nombre}")
            _ -> IO.puts("No se pudo unir.")
          end
        end
        loop()

      ["/exit"] ->
        IO.puts("Saliendo del modo comandos…")

      _ ->
        IO.puts("Comando no reconocido. /help")
        loop()
    end
  end

  defp buscar_equipo_por_nombre(nombre) do
    n = nombre |> String.downcase() |> String.trim()
    EquiposCSV.all() |> Enum.find(&(String.downcase(&1.nombre) == n))
  end
end
