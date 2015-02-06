using Color
using Images
using ImageView

const δ = 0.02                # one pixel in the floor plan equals δ meters

const n_air = 1.                      # refractive index for air
const n_concrete = 2.12 - 0.021im     # refractive index for concrete
                                      # the imaginary part conveys the absorption

const λ = 0.12       # for a 2.5 GHz signal, wavelength is ~ 12cm
const k = 2π / λ     # k is the wavenumber

function generateMu(filename)
	img = imread(filename)
	plan = reinterpret(Uint8, data(img));

	μ = similar(plan, Complex)
	μ[plan .>= 25] = (k / n_air)^2
	μ[plan .<  25] = (k / n_concrete)^2

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
			
			if (x-1)>0 && (x+1) <= dimx && (y-1)>0 && (y+1) <= dimy
				vs[i] = δ^-2
			else
				vs[i] = 1.0 # FIXME: what should happen when the matrix hits the boundaries?
			end
			
			i += 1
		end
	end

	return sparse(xs, ys, vs, length(μ), length(μ))
end

function plotMatrix(A, outfile)
	E = 20*log10(real(A) .* real(A))
	Ei = round(Integer, min(100, max(1, (int(1 .+ 100 .* (E .- minimum(E))/(maximum(E) - minimum(E)))))))

	#x = (E .- minimum(E)) / (maximum(E) - minimum(E))
	#println(x)
	#println("min, max ", minimum(x), maximum(x))
	cm = colormap("oranges", logscale=true)
	# cm = sequential_palette (20, 100, c=0.83, s=0.95, b=0.85, w=0.95, wcolor=RGB(1,1,0), dcolor=RGB(0.1,0.1,0.1), logscale=true)

	#Ei[plan .< 25] = 1;
	#Ei[f .!= 0] = 100;  # show antenna position

	field = Array(Float64, (size(A)[1], size(A)[2], 3))
	field[:,:,1] = [ cm[Ei[i]].r for i in 1:length(A) ]
	field[:,:,2] = [ cm[Ei[i]].g for i in 1:length(A) ]
	field[:,:,3] = [ cm[Ei[i]].b for i in 1:length(A) ]

	fim = colorim(permutedims(field, [2, 1, 3]))

	imwrite(fim, outfile)
end

# -------------------------------------------
# -------------------------------------------

function main()
	μ = generateMu("resources/plan3.png")
	S = generateMatrix(μ)

	for movex in 1:20:1420
		f = zeros(Complex, size(μ))
		f[movex, 650] = 1.0;              # our Wifi emitter antenna will be there;

		A = reshape(S \ vec(f), size(μ)...);
		#println("min(Re(A)): $(minimum(real(A))), max(Re(A): $(maximum(real(A)))")

		plotMatrix(A, "figs/move2/m-$(lpad(movex, 4, '0'))x650.png")
		f = 0; A = 0;
	end
end

# -------------------------------------------
# -------------------------------------------

main()
