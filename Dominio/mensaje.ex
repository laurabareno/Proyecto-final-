defmodule Mensaje do

  defstruct id: 0,
            contenido: "",
            remitente_id: nil,
            equipo_id: nil,
            canal: "general",
            timestamp: nil


  def crear(contenido, remitente_id, opts \\ []) do
    %__MODULE__{
      id: Keyword.get(opts, :id, System.unique_integer([:positive])),
      contenido: contenido,
      remitente_id: remitente_id,
      equipo_id: Keyword.get(opts, :equipo_id),
      canal: Keyword.get(opts, :canal, "general"),
      timestamp: DateTime.utc_now()
    }
  end

  def crear_desde_consola() do
    contenido = IO.gets("Escribe tu mensaje: ") |> String.trim()
    remitente = IO.gets("ID del remitente: ") |> String.trim() |> String.to_integer()
    canal     = IO.gets("Canal (general/equipo/sala_tematica): ") |> String.trim()

    crear(contenido, remitente, canal: canal)
  end

end 
