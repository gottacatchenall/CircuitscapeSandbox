module CircuitscapeInterface

using NeutralLandscapes
using Distributions
using Dates
using Circuitscape

const MIN_RESIST = 1.0

@kwdef struct PatchGenerator
    number_of_patches = 5
    dimensions = (64, 64)
    proportion_patch_cover = 0.3 
    explore_score = 0.5 # (0,1)
end

function _check_neighborhood(landscape, idx, value)
    X,Y = size(landscape)
    _inbounds(i) = i[1] > 0 && i[1] <= X && i[2] > 0 && i[2] <= Y
    _valid_index(i) = i != CartesianIndex(0,0) && _inbounds(idx+i)
    _check_neighbor(i) = (landscape[idx+i] != value && landscape[idx+i] != 0) ? landscape[idx+i] : 0
    [_check_neighbor(i) for i in CartesianIndices((-1:1, -1:1)) if _valid_index(i)]
end

function _check_overlap(landscape)
    vals = filter(!iszero, unique(landscape))
    conflicts = []
    for v in vals
        v_idx = findall(isequal(v), landscape)
        for i in v_idx
            neigh = _check_neighborhood(landscape, i, v)
            if sum(neigh) > 0
                push!(conflicts, (v, neigh[findfirst(!iszero, neigh)]))
                break
            end
        end 
    end

    conflict_adj = zeros(Bool, length(vals), length(vals))
    for (a,b) in conflicts
        i,j = findfirst(isequal(a), vals), findfirst(isequal(b), vals)
        conflict_adj[i,j] = 1
        conflict_adj[j,i] = 1
    end
    return vals, conflict_adj
end 

function _resolve_conflicts(landscape, vals, conflicts)
    ct = 2
    for i in axes(conflicts,1), j in i+1:size(conflicts,1)
        if conflicts[i,j] == 1
            landscape[findall(isequal(vals[i]), landscape)] .= ct
            landscape[findall(isequal(vals[j]), landscape)] .= ct
            ct += 1
        end 
    end
    y = copy(landscape)
    for (i,v) in enumerate(filter(!iszero, unique(landscape)))
        y[findall(isequal(v), landscape)] .= i
    end
    return y
end

function generate(pg::PatchGenerator) 
    landscape = rand(Patches(numpatches=pg.number_of_patches, σ_explore = 1/pg.explore_score, areaproportion=0.3), pg.dimensions)
    vals, conflicts = _check_overlap(landscape)
    landscape = _resolve_conflicts(landscape, vals, conflicts)
    landscape[findall(iszero, landscape)] .= NaN
    return landscape
end

@kwdef struct ResistanceGenerator
    number_of_categories = 5
    dimensions = (64, 64)
    category_area_distribution = Dirichlet(ones(number_of_categories))
    category_value_distribution = Gamma(1.5, 3)
    autocorrelation = 0.9
end

function generate(rg::ResistanceGenerator)
    landscape = rand(DiamondSquare(rg.autocorrelation), rg.dimensions)

    cats = rand(rg.category_area_distribution)
    s = 0.
    cutoffs = []
    for c in cats
        s += c
        push!(cutoffs, s)
    end
    classify!(landscape, cutoffs)

    resist_values = round.(rand(rg.category_value_distribution, rg.number_of_categories), digits=2)

    resist_surface = copy(landscape)
    for (i,v) in enumerate(unique(landscape))
        resist_surface[findall(isequal(v), landscape)] .= MIN_RESIST + resist_values[i]
    end
    resist_surface
end

function write_cs_input(mat, filename)
    input = 
    """
    ncols $(size(mat, 2))
    nrows $(size(mat, 1))
    xllcorner 1
    yllcorner 1
    cellsize 1
    NODATA_value NaN"""
    open(filename, "w") do f
        println(f, input)
        for r in eachrow(mat)
            map(x->print(f, x*" "), string.(r))
            print(f,"\n")
        end
    end 
end


function convert_to_circuitscape_inputs(resistance, patches, dir)
    write_dir = Base.Filesystem.mktempdir(dir; prefix="circuitscape_", cleanup=false)

    masked_resistance = copy(resistance)
    masked_resistance[findall(!isnan, patches)] .= MIN_RESIST

    resistance_path = joinpath(write_dir,"resistance.txt")
    patch_path = joinpath(write_dir,"patches.txt")
    ini_path = joinpath(write_dir, "params.ini")
    out_path = joinpath(write_dir, "output")

    write_cs_input(masked_resistance, resistance_path)
    write_cs_input(patches, patch_path)  

    default_ini = read(joinpath(@__DIR__, "default.ini"), String)

    ini = replace(default_ini, "{PATCH_PATH}" => patch_path)
    ini = replace(ini, "{RESISTANCE_PATH}" => resistance_path)
    ini = replace(ini, "{OUT_PATH}" => out_path)


    open(ini_path, "w") do f
        println(f, ini)
    end 

    return ini_path, write_dir
end 

function run_instance(
    rg, pg, write_dir
)
    resist = generate(rg)
    patches = generate(pg) 
    ini, rep_dir = convert_to_circuitscape_inputs(resist, patches, write_dir)
    try 
        compute(ini)
        return true
    catch e
        @info e
        @info "CS Errored (likely due to weirdness in the generated landscape). Trying again"
        rm(rep_dir, recursive=true)
        return false
    end
    
end


function run_circuitscape(;
    batch_size=64,
    number_of_patches = 5,
    raster_dimensions = (64, 64),
    proportion_patch_cover = 0.3,
    explore_score = 0.5,
    number_of_categories = 5,
    category_value_distribution_parameters = (1.5, 3), # Gamma(x,y)
    autocorrelation = 0.9,
)
    mkpath("data")

    rg = ResistanceGenerator(
        dimensions=raster_dimensions,
        category_value_distribution = Gamma(category_value_distribution_parameters...),
        autocorrelation = autocorrelation,
        number_of_categories = number_of_categories
    )
    pg = PatchGenerator(
        number_of_patches = number_of_patches,
        dimensions = raster_dimensions,
        proportion_patch_cover = proportion_patch_cover,
        explore_score = explore_score
    )

    write_dir = joinpath("data", "batch_"*string(now()))
    mkdir(write_dir)

    r = 1
    while r < batch_size
        @info "Run $r / $batch_size"
        if run_instance(rg, pg, write_dir)
            r += 1
        end
    end 

    return joinpath(@__DIR__, write_dir)
end 

end 

