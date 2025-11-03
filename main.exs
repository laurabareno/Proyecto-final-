defmodule Main do

  defp prompt(msg), do: IO.gets(msg) |> to_string() |> String.trim()

  defp prompt_int(msg) do
    case Integer.parse(prompt(msg)) do
      {n, _} -> n
      :error ->
        IO.puts(" Ingresa un número válido.")
        prompt_int(msg)
    end
  end

  defp maybe_put(map, _key, val) when val in [nil, ""], do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, val)

  defp prompt_atom_in(msg, valid) do
    v = prompt(msg) |> String.downcase()
    if v in Enum.map(valid, &Atom.to_string/1), do: String.to_atom(v), else: (IO.puts(" Valor inválido."); prompt_atom_in(msg, valid))
  end

  defp puts_separator(), do: IO.puts("-------------------------------------------")

  # Acciones básicas
  defp accion_registrar_usuario do
    nombre = prompt("Nombre: ")
    id = prompt_int("ID (entero): ")
    correo = prompt("Correo: ")
    rol = prompt("Rol (participante/mentor): ") |> String.downcase()

    u =
      case rol do
        "mentor" -> Usuario.crear(nombre, id, correo, "mentor")
        _ -> Usuario.crear(nombre, id, correo, "participante")
      end

    UsuariosCSV.upsert(u)
    IO.puts(" Usuario registrado correctamente.")
  end

  defp accion_crear_equipo do
    nombre = prompt("Nombre del equipo: ")
    tema = prompt("Tema o afinidad: ")
    {:ok, eq} = EquiposCSV.crear_por_tema(nombre, tema)
    IO.puts(" Equipo '#{eq.nombre}' creado con ID #{eq.id}.")
  end

  defp accion_asignar_usuario_equipo do
    user_id = prompt_int("ID del usuario: ")
    equipo_id = prompt_int("ID del equipo: ")

    case {UsuariosCSV.get(user_id), EquiposCSV.get(equipo_id)} do
      {nil, _} -> IO.puts(" Usuario no existe.")
      {_, nil} -> IO.puts(" Equipo no existe.")
      {_, _} ->
        EquiposCSV.agregar_miembro(equipo_id, user_id)
        IO.puts("Usuario asignado al equipo.")
    end
  end

  defp accion_listar_equipos_activos do
  case GestionEquipos.listar_equipos_activos() do
  {:ok, equipos} when equipos != [] ->
    IO.puts("\n EQUIPOS ACTIVOS ")
    Enum.each(equipos, fn e ->
      IO.puts("""
      ID: #{e.id}
      Nombre: #{e.nombre}
      Tema: #{e.tema}
      Participantes: #{if e.participantes == [], do: "Ninguno", else: Enum.join(Enum.map(e.participantes, &to_string/1), ", ")}
      }
      ---------------------------
      """)
    end)

  {:ok, []} ->
    IO.puts(" No hay equipos activos registrados.")

  {:error, msg} ->
    IO.puts(" Error al listar equipos: #{msg}")

  _ ->
    IO.puts(" No se pudo obtener la lista de equipos.")
end

end


  defp accion_registrar_idea_proyecto do
    nombre = prompt("Nombre del proyecto: ")
    descripcion = prompt("Descripción breve: ")
    tema = prompt("Tema/Categoría: ")
    equipo_id = prompt("ID del equipo (ENTER si no aplica): ")

    opts = if equipo_id == "", do: [], else: [equipo_id: String.to_integer(equipo_id)]
    {:ok, p} = GestionProyectos.registrar_idea(nombre, descripcion, tema, opts)
    IO.puts(" Proyecto '#{p.nombre}' creado con ID #{p.id}.")
  end

  defp accion_asignar_equipo_proyecto do
    p_id = prompt_int("ID del proyecto: ")
    eq_id = prompt_int("ID del equipo: ")
    GestionProyectos.asignar_equipo(p_id, eq_id)
    IO.puts(" Equipo asignado al proyecto.")
  end

  defp accion_asignar_mentor_proyecto do
    p_id = prompt_int("ID del proyecto: ")
    mentor_id = prompt_int("ID del mentor: ")
    GestionProyectos.asignar_mentor(p_id, mentor_id)
    IO.puts(" Mentor asignado al proyecto.")
  end

  defp accion_listar_proyectos_por_estado do
    estado = prompt_atom_in("Estado (propuesto/en_progreso/finalizado/descartado): ", [:propuesto, :en_progreso, :finalizado, :descartado])
    GestionProyectos.listar_por_estado(estado)
    |> Enum.each(fn p -> IO.puts("• [#{p.id}] #{p.nombre} (#{p.tema}) estado=#{p.estado}") end)
  end

  defp accion_enviar_mensaje do
    contenido = prompt("Contenido del mensaje: ")
    remitente = prompt_int("ID remitente: ")
    canal = prompt("Canal (general/equipo/sala_tematica): ")
    opts =
      case canal do
        "equipo" -> [canal: "equipo", equipo_id: prompt_int("ID del equipo: ")]
        "sala_tematica" -> [canal: "sala_tematica"]
        _ -> [canal: "general"]
      end

    ChatService.enviar(contenido, remitente, opts)
    IO.puts(" Mensaje enviado.")
  end

  defp accion_listar_mensajes_general do
    ChatService.listar_general()
    |> Enum.each(fn m -> IO.puts("[#{m.id}] (#{m.timestamp}) u#{m.remitente_id} → #{m.contenido}") end)
  end

  defp accion_listar_mensajes_equipo do
    eq = prompt_int("ID del equipo: ")
    ChatService.listar_equipo(eq)
    |> Enum.each(fn m -> IO.puts("[#{m.id}] (#{m.timestamp}) u#{m.remitente_id} → #{m.contenido}") end)
  end

  defp accion_crear_feedback do
  eq = prompt_int("ID del equipo: ")
  autor = prompt_int("ID del mentor: ")
  tipo = prompt_atom_in("Tipo (comentario/revision/puntaje): ", [:comentario, :revision, :puntaje])
  titulo = prompt("Título: ")
  detalle = prompt("Detalle: ")

  attrs =
    case tipo do
      :puntaje ->
        Keyword.merge(
          [tipo: tipo, titulo: titulo, detalle: detalle],
          puntaje: prompt_int("Puntaje 0-100: ")
        )

      :revision ->
        Keyword.merge(
          [tipo: tipo, titulo: titulo, detalle: detalle],
          acciones: String.split(prompt("Acciones separadas por |: "), "|")
        )

      _ ->
        [tipo: tipo, titulo: titulo, detalle: detalle]
    end

  case FeedbackService.crear(eq, autor, attrs) do
    {:ok, _fb} ->
      IO.puts(" Feedback guardado correctamente en feedback.csv")

    {:error, :equipo_no_existe} ->
      IO.puts(" El equipo con ID #{eq} no existe.")

    {:error, :autor_no_existe} ->
      IO.puts(" El autor con ID #{autor} no existe.")

    {:error, :autor_no_es_mentor} ->
      IO.puts(" El usuario con ID #{autor} no es un mentor.")

    {:error, razon} ->
      IO.puts(" Error al crear el feedback: #{inspect(razon)}")

    otro ->
      IO.puts(" Error desconocido al crear el feedback: #{inspect(otro)}")
  end
end

  defp accion_listar_feedback_equipo do
    eq = prompt_int("ID del equipo: ")
    FeedbackService.listar_por_equipo(eq)
    |> Enum.each(fn f -> IO.puts("[#{f.id}] #{f.tipo} (#{f.titulo}) → #{f.detalle}") end)
  end

  #  Actualizar / Eliminar Usuarios
defp accion_actualizar_usuario do
  id = prompt_int("ID del usuario a actualizar: ")
  case UsuariosCSV.get(id) do
    nil -> IO.puts(" Usuario #{id} no existe.")
    %Usuario{} = u ->
      IO.puts("Dejar campo vacío para no modificarlo.")
      nombre = prompt("Nombre (actual: #{u.nombre}): ")
      correo = prompt("Correo (actual: #{u.correo}): ")
      rol = prompt("Rol (participante/mentor) (actual: #{u.rol}): ")

      cambios =
        %{}
        |> maybe_put(:nombre, nombre)
        |> maybe_put(:correo, correo)
        |> maybe_put(:rol, (if rol == "", do: nil, else: rol))

      case UsuariosCSV.update(id, cambios) do
        {:ok, _} -> IO.puts(" Usuario actualizado.")
        {:error, r} -> IO.puts(" Error al actualizar: #{inspect(r)}")
      end
  end
end

defp accion_eliminar_usuario do
  id = prompt_int("ID del usuario a eliminar: ")
  case UsuariosCSV.get(id) do
    nil -> IO.puts(" Usuario #{id} no existe.")
    _ ->
      UsuariosCSV.delete(id)
      IO.puts(" Usuario eliminado.")
  end
end

# Actualizar / Eliminar Equipos
defp accion_actualizar_equipo do
  id = prompt_int("ID del equipo a actualizar: ")
  case EquiposCSV.get(id) do
    nil -> IO.puts(" Equipo #{id} no existe.")
    %Equipo{} = e ->
      IO.puts("Dejar campo vacío para no modificarlo.")
      nombre = prompt("Nombre (actual: #{e.nombre}): ")
      tema = prompt("Tema (actual: #{e.tema}): ")
      estado = prompt("Estado (activo/inactivo) (actual: #{e.estado}): ")

      cambios =
        %{}
        |> maybe_put(:nombre, nombre)
        |> maybe_put(:tema, tema)
        |> maybe_put(:estado, (if estado == "", do: nil, else: String.to_atom(String.downcase(estado))))

      case EquiposCSV.update(id, cambios) do
        {:ok, _} -> IO.puts(" Equipo actualizado.")
        {:error, r} -> IO.puts("Error al actualizar equipo: #{inspect(r)}")
      end
  end
end

defp accion_eliminar_equipo do
  id = prompt_int("ID del equipo a eliminar: ")
  case EquiposCSV.get(id) do
    nil -> IO.puts(" Equipo #{id} no existe.")
    _ ->
      EquiposCSV.delete(id)
      IO.puts(" Equipo eliminado.")
  end
end

# Actualizar / Eliminar Proyectos
defp accion_actualizar_proyecto do
  id = prompt_int("ID del proyecto a actualizar: ")
  case ProyectosCSV.get(id) do
    nil -> IO.puts(" Proyecto #{id} no existe.")
    %Proyecto{} = p ->
      IO.puts("Dejar campo vacío para no modificarlo.")
      nombre = prompt("Nombre (actual: #{p.nombre}): ")
      descripcion = prompt("Descripción (actual: #{p.descripcion}): ")
      estado = prompt("Estado (propuesto/en_progreso/finalizado/descartado) (actual: #{p.estado}): ")

      cambios =
        %{}
        |> maybe_put(:nombre, nombre)
        |> maybe_put(:descripcion, descripcion)
        |> maybe_put(:estado, (if estado == "", do: nil, else: String.to_atom(String.downcase(estado))))

      case ProyectosCSV.update(id, cambios) do
        {:ok, _} -> IO.puts("Proyecto actualizado.")
        {:error, r} -> IO.puts("Error al actualizar proyecto: #{inspect(r)}")
      end
  end
end

defp accion_eliminar_proyecto do
  id = prompt_int("ID del proyecto a eliminar: ")
  case ProyectosCSV.get(id) do
    nil -> IO.puts(" Proyecto #{id} no existe.")
    _ ->
      ProyectosCSV.delete(id)
      IO.puts(" Proyecto eliminado.")
  end
end

defp accion_actualizar_feedback do
  id = prompt_int("ID del feedback a actualizar: ")

  case FeedbackCSV.get(id) do
    nil ->
      IO.puts(" No existe un feedback con ese ID.")

    f ->
      IO.puts("Deja vacío el campo que no quieras cambiar.")
      titulo = prompt("Título (actual: #{f.titulo}): ")
      detalle = prompt("Detalle (actual: #{f.detalle}): ")
      puntaje =
        if f.tipo == :puntaje do
          p = prompt("Puntaje (actual: #{f.puntaje}): ")
          if p == "", do: nil, else: String.to_integer(p)
        else
          nil
        end
      estado = prompt("Estado (pendiente/en_progreso/resuelto) (actual: #{f.estado_accion}): ")

      nuevos_datos =
        %{}
        |> maybe_put(:titulo, if(titulo == "", do: nil, else: titulo))
        |> maybe_put(:detalle, if(detalle == "", do: nil, else: detalle))
        |> maybe_put(:puntaje, puntaje)
        |> maybe_put(:estado_accion, if(estado == "", do: nil, else: String.to_atom(estado)))

      case FeedbackService.actualizar(id, nuevos_datos) do
        {:ok, _} -> IO.puts("Feedback actualizado correctamente.")
        {:error, :feedback_no_existe} -> IO.puts(" No se encontró el feedback.")
        _ -> IO.puts(" Error al actualizar el feedback.")
      end
  end
end

  # NUEVA OPCIÓN: modo comandos
  defp accion_modo_comandos do
    IO.puts("Entrando al modo comandos... Usa /help para ver los comandos disponibles.")
    Comandos.start()
  end


    #Menú
  defp menu_text() do
    """
    \n==== HACKATHON CLI ====
    [1] Registrar usuario
    [2] Crear equipo
    [3] Asignar usuario a equipo
    [4] Listar equipos activos
    [5] Registrar idea de proyecto
    [6] Asignar equipo a proyecto
    [7] Asignar mentor a proyecto
    [8] Listar proyectos por estado
    [9] Enviar mensaje
    [10] Listar mensajes GENERAL
    [11] Listar mensajes EQUIPO
    [12] Crear feedback
    [13] Listar feedback por equipo
    [14] Actualizar usuario
    [15] Eliminar usuario
    [16] Actualizar equipo
    [17] Eliminar equipo
    [18] Actualizar proyecto
    [19] Eliminar proyecto
    [20] Actualizar feedback
    [21] Modo comandos (/teams, /project, /join, /chat, /help)
    [0] Salir
    Selección:
    """
  end


  # Bucle principal
  def start do
    IO.puts(" Bienvenido al sistema de gestión de Hackathon!")
    loop()
  end

  defp loop do
    case prompt(menu_text()) do
      "1" -> puts_separator(); accion_registrar_usuario(); loop()
      "2" -> puts_separator(); accion_crear_equipo(); loop()
      "3" -> puts_separator(); accion_asignar_usuario_equipo(); loop()
      "4" -> puts_separator(); accion_listar_equipos_activos(); loop()
      "5" -> puts_separator(); accion_registrar_idea_proyecto(); loop()
      "6" -> puts_separator(); accion_asignar_equipo_proyecto(); loop()
      "7" -> puts_separator(); accion_asignar_mentor_proyecto(); loop()
      "8" -> puts_separator(); accion_listar_proyectos_por_estado(); loop()
      "9" -> puts_separator(); accion_enviar_mensaje(); loop()
      "10" -> puts_separator(); accion_listar_mensajes_general(); loop()
      "11" -> puts_separator(); accion_listar_mensajes_equipo(); loop()
      "12" -> puts_separator(); accion_crear_feedback(); loop()
      "13" -> puts_separator(); accion_listar_feedback_equipo(); loop()
      "14" -> puts_separator(); accion_actualizar_usuario(); loop()
      "15" -> puts_separator(); accion_eliminar_usuario(); loop()
      "16" -> puts_separator(); accion_actualizar_equipo(); loop()
      "17" -> puts_separator(); accion_eliminar_equipo(); loop()
      "18" -> puts_separator(); accion_actualizar_proyecto(); loop()
      "19" -> puts_separator(); accion_eliminar_proyecto(); loop()
      "20" -> puts_separator(); accion_actualizar_feedback(); loop()
      "21" -> puts_separator(); accion_modo_comandos(); loop()
      "0" -> IO.puts("¡Hasta luego!")
      _ -> IO.puts("Opción inválida."); loop()
    end
  end
end


Main.start()
