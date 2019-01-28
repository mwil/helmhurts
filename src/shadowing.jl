import Colors
import Images

const INFILE = "resources/floorplan-wf.png"
const N_COLORS = 20

const TX_POS = 425, 870

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

function main()
    plan = Images.load(INFILE)

    PL = pathloss(size(plan)...)
    S = shadowing(plan)
    E = PL .- S

    E[E .< -90] .= -90    # simulate the noise floor to have a better scaling in the colormap (arbitrary value!)
    E[TX_POS...] = 1.0   # remove the singularity at the antenna position

    cm = reverse(Colors.colormap("blues", N_COLORS))
    minE, maxE = minimum(E), maximum(E)
    Ei = round.(Int, min.(N_COLORS, max.(1, (round.(Int, 1 .+ N_COLORS * (E .- minE)/(maxE - minE))))))

    field = [cm[ei] for ei in Ei]

    # Show walls by using the maximum color
    field[plan .== 0] .= Images.RGB(1, 1, 1)

    Images.save(joinpath("figs", "shtest.png"), field)
end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

"""
Find the pixels on a straight line from (x0,y0) to (x1,y1).

Parameters
x0,y0: starting coordinates of the line
x1,y1: end coordinates of the line

Returns
A list of (x,y) tuples that are touched by the line, including start and end points."""
function line(x0::Int, y0::Int, x1::Int, y1::Int)
    result = Array{Tuple{Int, Int}}(undef, 0) # empty array of (x,y) tuples
    rev = identity

    if abs(y1-y0) ≤ abs(x1-x0)
        x0, y0, x1, y1 = y0, x0, y1, x1
        rev = reverse
    end

    leny = abs(y1 - y0)

    for i in 0:leny
        push!(result, rev((round(Int, i//leny * (x1-x0) + x0), (y1>y0 ? 1 : -1)*i + y0)))
    end

    return result
end
# -----------------------------------------------------------------------------

"""
For each pixel on the floor plan, find the number of wall pixels towards the signal source
and reduce the received signal strength by a certain factor.

Parameters:
    `plan`:         a floor plan with white pixels signifying air, the rest are interpreted as walls.
    `dB_per_pixel`: regulates the amount of fading that is induced by a single wall pixel."""
function shadowing(plan; dB_per_pixel=0.1)
    S = zeros(Float64, size(plan)) .- 1.0   # initialize unvisited elements in the matrix with -1
    dimx, dimy = size(S)

    # count the number of pixels on the path that are non-white (walls)
    for y in 1:dimy, x in 1:dimx
        if S[x,y] < 0.0   # if S[x,y] == -1, we have not visited this element before, otherwise skip it
            pixels = line(TX_POS[1], TX_POS[2], x, y)  # start the line from the antenna
            wallcnt = 0.0

            for pixel in pixels
                wallcnt += (plan[pixel...]≠1) ? dB_per_pixel : 0.0
                S[pixel...] = wallcnt  # set all pixels that we visit coming from the antenna as well
            end
        end
    end

    return S
end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

"""
Calculate distance matrix Dist and pathloss matrix PL to each matrix element.

Parameters:
    `scaling`: a correction factor to ensure that the distances on the floorplan result in a sane amount of fading."""
function pathloss(dimx::Int, dimy::Int; scaling=0.2)
    Dist = zeros(Float64, dimx, dimy)

    for y in 1:dimy, x in 1:dimx
        Dist[x,y] = abs(complex(TX_POS...) - complex(x,y)) * scaling
    end

    Dist[TX_POS...] = Dist[TX_POS[1]-1, TX_POS[2]-1]

    PL = similar(Dist)
    PL = 20 * log10.(Dist.^-2)
end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

main()

