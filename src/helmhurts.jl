using Color
using Images
using ImageView

const δ = 0.02                # one pixel in the floor plan equals δ meters

const n_air = 1.                      # refractive index for air
const n_concrete = 2.12 - 0.021im     # refractive index for concrete
                                      # the imaginary part conveys the absorption

const λ = 0.12     # for a 2.5 GHz signal, wavelength is ~ 12cm
const k = 2π/λ     # k is the wavenumber

const infile = "resources/plan3.png"

const txX = 400
const txY = 550

function generateMu(filename)
	img = imread(filename)
	plan = reinterpret(Uint8, data(img));

	μ = similar(plan, Complex)
	μ[plan .== 255] = (k/n_air)^2            # white signifies empty space
  μ[plan .≠  255] = (k/n_concrete)^2       # everything else are obstactles

	return μ
end

function generateMatrix(μ)
	dimx, dimy = size(μ)  # spatial dimensions

	xs = Array(Int,     5*length(μ))
	ys = Array(Int,     5*length(μ))
	vs = Array(Complex, 5*length(μ))
	i = 1

	for x in 1:dimx, y in 1:dimy
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
				vs[i] = 1000.0 # FIXME: what should happen when the matrix hits the boundaries?
			end

			i += 1
		end
	end

	return sparse(xs, ys, vs, length(μ), length(μ))
end

function plotMatrix(A, outfile)
	E = 20*log10(real(A) .* real(A))
	Ei = round(Integer, min(100, max(1, (int(1 .+ 100 .* (E .- minimum(E))/(maximum(E) - minimum(E)))))))

	cm = colormap("oranges", logscale=true)

	#img = imread(infile)
	#plan = reinterpret(Uint8, data(img));
	#Ei[plan .== 0] = 100;
	Ei[txX-1:txX+1, txY-1:txY+1] = 1;  # show antenna position

	field = Array(Float64, (size(A)[1], size(A)[2], 3))
	field[:,:,1] = [ cm[ei].r for ei in Ei ]
	field[:,:,2] = [ cm[ei].g for ei in Ei ]
	field[:,:,3] = [ cm[ei].b for ei in Ei ]

	fim = colorim(permutedims(field, [2, 1, 3]))

	imwrite(fim, outfile)
end

## -------------------------------------------
## -------------------------------------------

function main()
  println("Starting operation …")
	μ = generateMu(infile)
	S = generateMatrix(μ)

	for movex in (txX,)#1381:20:1420
		f = zeros(Complex, size(μ))
		f[movex, txY] = 1.0;              # our Wifi emitter antenna will be there;

    println("Solving the matrix equation …")
		A = reshape(S \ vec(f), size(μ)...);

    println("Plotting stuff …")
		plotMatrix(A, "figs/h-$(lpad(txX, 4, '0'))x$(lpad(txY, 4, '0')).png")
	end
end

## -------------------------------------------
## -------------------------------------------

main()
