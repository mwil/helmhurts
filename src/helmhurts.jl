import Colors
import Images

# one pixel in the floor plan equals δ meters
const δ = 0.01

# refractive index for air
const n_air = 1.

# refractive index for concrete the imaginary part conveys the absorption
const n_concrete = 2.12 - 0.021im

# for a 2.5 GHz signal, wavelength is ~ 12cm
const λ = 0.12

# k is the wavenumber
const k = 2π/λ

const INFILE = "resources/floorplan-wf.png"
const N_COLORS = 20

const txX, txY = 425, 870

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

function main()
    println("Starting operation …")
    μ = generateMu(INFILE)
    M = generateM(μ)

    for movey in (txY,)
        f = zeros(size(μ))
        f[txX, movey] = 2e3

        println("Solving the matrix equation A=M\\f …")
        A = reshape(M\vec(f), size(μ))

        println("Plotting matrix A …")
        plotMatrix(A, joinpath("figs", "h-$(lpad(txX, 4, '0'))x$(lpad(movey, 4, '0')).png"))
        A=0;f=0; # avoid sporadic memory overflows ...
    end
end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

# Generate a complex array with material information (positions of walls/air)
function generateMu(infile::String)
    plan = Images.load(infile)

    μ = zeros(Complex128, size(plan))
    μ[plan .== 1] = (k/n_air)^2            # white signifies empty space
    μ[plan .≠  1] = (k/n_concrete)^2       # everything else are obstactles

    return μ
end
# -----------------------------------------------------------------------------

function generateM(μ::Array{Complex128})
    dimx, dimy = size(μ)  # spatial dimensions

    xs = zeros(Int, 5*length(μ))
    ys = zeros(Int, 5*length(μ))
    vs = zeros(Complex128, 5*length(μ))
    i = 1

    for y in 1:dimy, x in 1:dimx
        xm = (x+dimx-2) % dimx + 1
        xp =          x % dimx + 1
        ym = (y+dimy-2) % dimy + 1
        yp =          y % dimy + 1

        xs[i] = sub2ind(size(μ), x, y)
        ys[i] = sub2ind(size(μ), x, y)
        vs[i] = μ[x,y] - 4δ^-2
        i += 1

        for idx in ((xp, y), (xm, y), (x, yp), (x, ym))
            xs[i] = sub2ind(size(μ), x, y)
            ys[i] = sub2ind(size(μ), idx...)

            if 1<x<dimx && 1<y<dimy
                vs[i] = δ^-2
            else
                # FIXME: what should happen when the matrix hits the boundaries?
                vs[i] = 1e-9
            end

            i += 1
        end
    end

    return sparse(xs, ys, vs, length(μ), length(μ))
end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

function plotMatrix(A::Array{Complex128}, outfile::String)
    plan = Images.load(INFILE)

    # A is amplitude field, calculate the signal power
    E = 20*log10(real(A) .* real(A))

    # Apply lower limit to the power to add a noise floor
    E[E .< -105.0] = -105.0

    minE, maxE = minimum(E), maximum(E)
    # Limit the Ei matrix to values in 1..N_COLORS
    Ei = round(Int, min(N_COLORS, max(1, round(Int, 1 + N_COLORS*(E .- minE)/(maxE - minE)))))

    cm = reverse(Colors.colormap("blues", N_COLORS))
    # Choose colors from the colormap according to the Ei int values
    field = [cm[ei] for ei in Ei]

    # Show walls by using the maximum color
    field[plan .== 0] = Images.RGB(1, 1, 1)
    # Show the position of the antenna by a white block
    field[txX-3:txX+3, txY-3:txY+3] = Images.RGB(1, 1, 1)

    fim = Images.save(outfile, Images.colorim(field))
end

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

main()

