import Colors
import Images

const INFILE = "resources/floorplan-wf.png"
const N_COLORS = 20

const TX_POS = 425, 870

function pathloss(dimx::Int, dimy::Int; scaling=0.2)
    # calculate distance matrix Dist and pathloss matrix PL
    Dist = zeros(Float64, (dimx, dimy))

    for x in 1:dimx, y in 1:dimy
        Dist[x,y] = abs((TX_POS[1]+TX_POS[2]*im) - (x+y*im)) * scaling
    end

    Dist[TX_POS...] = Dist[TX_POS[1]-1, TX_POS[2]-1]

    PL = similar(Dist, Float64)
    PL = 20 .* log10(Dist .^ -2)
end

function main()
    plan = Images.load(INFILE)
    dimx, dimy = size(plan)

    PL = pathloss(dimx, dimy)
    E = PL

    E[E .< -90] = -90    # simulate the noise floor to have a better scaling in the colormap
    E[TX_POS...] = 1.0   # remove the singularity at the antenna position

    cm = reverse(Colors.colormap("blues", N_COLORS))
    minE, maxE = minimum(E), maximum(E)
    Ei = round(Integer, min(N_COLORS, max(1, (round(Integer, 1 .+ N_COLORS .* (E .- minE)/(maxE - minE))))))

    field = [cm[ei] for ei in Ei]

    # Show walls by using the maximum color
    field[plan .== 0] = Images.RGB(1, 1, 1)

    Images.save("figs/pltest.png", Images.colorim(field))
end

main()

