
using Agents
using Random
using Pathfinding 
using LinearAlgebra: size

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


is_free(x::Int, y::Int) = 
    1 ≤ y ≤ size(matrix, 1) && 1 ≤ x ≤ size(matrix, 2) && matrix[y, x] == 1 


@agent Ghost PathfindingAgent{2} begin
    type::String = "Ghost"
end

# Se define un agente PacMan como objetivo.
@agent PacMan GridAgent{2} begin
    type::String = "PacMan"
end


function agent_step!(agent::Ghost, model)
    
    pacman = findfirst(a -> a.type == "PacMan", allagents(model))
    
    if !isnothing(pacman)
        pacman_pos = model[pacman].pos
        
        
        set_target!(agent, pacman_pos, model.pathfinder)
        
        
        move_along_route!(agent, model, model.pathfinder)
    end
end


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


function is_walkable(pos, model)
    x, y = pos
    
    return is_free(x, y) 
end

function initialize_model()
    
    dims = (size(matrix, 2), size(matrix, 1)) # (columnas, filas)
    pathfinder = AStar(
        dims; 
        walkable = is_walkable, 
        cost_metric = (p1, p2) -> 1, # Costo uniforme
        diagonal_movement = false 
    )
    
    
    space = GridSpace(dims; periodic=false, metric=:manhattan) 
    
    
    model = StandardABM(
        Union{Ghost, PacMan}, 
        space; 
        agent_step!, 
        model_step! = dummystep,
        properties = Dict(:pathfinder => pathfinder) # Almacena el pathfinder
    )

    
    ghost_start = (9, 9) # Posición libre cerca del centro
    pacman_start = (2, 2) # Otra posición libre
    
   
    add_agent_pos!(Ghost(nextid(model), ghost_start, "Ghost"), model)
    add_agent_pos!(PacMan(nextid(model), pacman_start, "PacMan"), model)
    
    return model 
end