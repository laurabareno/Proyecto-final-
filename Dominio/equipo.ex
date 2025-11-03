defmodule Equipo do

  defstruct id: 0,
            nombre: "",
            tema: "",
            estado: :activo,
            participantes: [],
            mentores: []

  def crear(nombre, tema, opts \\ []) do
    id = Keyword.get(opts, :id, System.unique_integer([:positive]))
    estado = Keyword.get(opts, :estado, :activo)

    %Equipo{
      id: id,
      nombre: nombre,
      tema: tema,
      estado: estado,
      participantes: [],
      mentores: []
    }
    
  end
end
