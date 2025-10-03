# agent.jl
using Agents
using Random
using Agents.Pathfinding # Necesario para la funcionalidad A*
using LinearAlgebra: size

# ====================================================================
# DEFINICIÓN DEL MAPA Y AGENTES
# ====================================================================

# Laberinto: 0 es pared, 1 es camino. Se mantiene el nombre 'matrix'.
# matrix[fila, columna] = matrix[y, x]
const matrix = [
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

# Función auxiliar para verificar si una posición (x, y) es un camino (1)
is_free(x::Int, y::Int) = 
    1 ≤ y ≤ size(matrix, 1) && 1 ≤ x ≤ size(matrix, 2) && matrix[y, x] == 1 

# --------------------------------------------------------------------
# Agentes
# --------------------------------------------------------------------

# El agente Ghost ahora debe heredar de PathfindingAgent para la inteligencia A*.
@agent Ghost PathfindingAgent{2} begin
    type::String = "Ghost"
end

# Se define un agente PacMan como objetivo.
@agent PacMan GridAgent{2} begin
    type::String = "PacMan"
end

# ====================================================================
# LÓGICA DEL MOVIMIENTO
# ====================================================================

# Movimiento inteligente para el Fantasma
function agent_step!(agent::Ghost, model)
    # 1. Encontrar la posición de PacMan.
    # Buscamos el primer agente que sea un PacMan.
    pacman = findfirst(a -> a.type == "PacMan", allagents(model))
    
    if !isnothing(pacman)
        pacman_pos = model[pacman].pos
        
        # 2. Asignar el objetivo (PacMan) y calcular la ruta A*.
        # set_target! calcula la ruta y la almacena en el agente.
        set_target!(agent, pacman_pos, model.pathfinder)
        
        # 3. Mover el agente un paso a lo largo de la ruta calculada.
        # move_along_route! implementa el movimiento inteligente.
        move_along_route!(agent, model, model.pathfinder)
    end
end

# Movimiento errático para PacMan (simplemente para que se mueva)
function agent_step!(agent::PacMan, model)
    x, y = agent.pos
    candidates = ((x+1, y), (x-1, y), (x, y+1), (x, y-1)) 
    valid_moves = Tuple{Int,Int}[]
    for (nx, ny) in candidates 
        if is_free(nx, ny) 
            push!(valid_moves, (nx, ny)) 
        end 
    end 
    if !isempty(valid_moves) 
        move_agent!(agent, rand(valid_moves), model) 
    end 
end


# ====================================================================
# INICIALIZACIÓN DEL MODELO
# ====================================================================

# Función auxiliar para determinar si una celda es transitable para el pathfinder
function is_walkable(pos, model)
    x, y = pos
    # El laberinto 'matrix' tiene las dimensiones (filas, columnas), por eso usamos matrix[y, x]
    return is_free(x, y) 
end

function initialize_model()
    # 1. Crear el Pathfinding Space (AStar)
    dims = (size(matrix, 2), size(matrix, 1)) # (columnas, filas)
    pathfinder = AStar(
        dims; 
        walkable = is_walkable, 
        cost_metric = (p1, p2) -> 1, # Costo uniforme
        diagonal_movement = false 
    )
    
    # 2. Inicializar el modelo con Pathfinding
    space = GridSpace(dims; periodic=false, metric=:manhattan) 
    
    # El modelo debe aceptar ambos tipos de agentes (Union)
    model = StandardABM(
        Union{Ghost, PacMan}, 
        space; 
        agent_step!, 
        model_step! = dummystep,
        properties = Dict(:pathfinder => pathfinder) # Almacena el pathfinder
    )

    # 3. Posiciones iniciales (se elige una posición libre)
    ghost_start = (9, 9) # Posición libre cerca del centro
    pacman_start = (2, 2) # Otra posición libre
    
    # 4. Alta de los agentes
    # Usamos add_agent_pos! ya que estamos especificando la posición directamente
    add_agent_pos!(Ghost(nextid(model), ghost_start, "Ghost"), model)
    add_agent_pos!(PacMan(nextid(model), pacman_start, "PacMan"), model)
    
    return model 
end