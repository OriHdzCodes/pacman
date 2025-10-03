using Agents
using Random

@agent struct Ghost(GridAgent{2})
    type::String = "Ghost"
end

matrix = [
    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
    0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 0;
    0 1 0 1 0 0 0 1 1 1 0 1 0 1 0 1 0;
    0 1 1 1 0 1 0 0 0 0 0 1 0 1 1 1 0;
    0 1 0 0 0 1 1 1 1 1 1 1 0 0 0 1 0;
    0 1 0 1 0 1 0 0 0 0 0 1 1 1 0 1 0;
    0 1 1 1 0 1 0 1 1 1 0 1 0 1 0 1 0;
    0 1 0 1 0 1 0 1 1 1 0 1 0 1 0 1 0;
    0 1 0 1 1 1 0 0 1 0 0 1 0 1 1 1 0;
    0 1 0 0 0 1 1 1 1 1 1 1 0 0 0 1 0;
    0 1 1 1 0 1 0 0 0 0 0 1 0 1 1 1 0;
    0 1 0 1 0 1 0 1 1 1 0 0 0 1 0 1 0;
    0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 0;
    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
]

function agent_step!(agent, model)
    # Para obtener la posición actual
    current_x, current_y = agent.pos
    
    # Definir los cuatro movimientos posibles
    potential_moves = [
        (current_x + 1, current_y), 
        (current_x - 1, current_y),
        (current_x, current_y + 1),
        (current_x, current_y - 1)
    ]
    
    valid_moves = Tuple{Int, Int}[] # Arreglo para guardar los espacios por los que puede pasar (1)
    
    # Dimensiones de la matriz: (filas, columnas)
    rows, cols = size(matrix)

    for (next_x, next_y) in potential_moves
        # Verifica los limites de la matriz
        if 1 <= next_x <= cols && 1 <= next_y <= rows
            # Verifica si la celda es un camino (1)
            if matrix[next_y, next_x] == 1
                push!(valid_moves, (next_x, next_y))
            end
        end
    end

    # Selecciona una posicion valida aleatoriamente y mueve el agente
    if !isempty(valid_moves)
        new_pos = rand(valid_moves)
        move_agent!(agent, new_pos, model)
    end
end

function initialize_model()
    space = GridSpace((5,5); periodic = false, metric = :manhattan)
    model = StandardABM(Ghost, space; agent_step!)
    return model
end

model = initialize_model()
a = add_agent!(Ghost, pos=(3, 3), model)