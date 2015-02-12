import Color
import Images

const INFILE = "resources/floorplan-wf.png"
const N_COLORS = 20

const TX_POS = 870, 425

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
	img = Images.imread(INFILE)
	plan = reinterpret(Uint8, Images.data(img));
	dimx, dimy = size(plan)

	PL = pathloss(dimx, dimy)
	E = PL

	E[E .< -90] = -90    # simulate the noise floor to have a better scaling in the colormap
	E[TX_POS...] = 1.0   # remove the singularity at the antenna position

	cm = reverse(Color.colormap("blues", N_COLORS))
	minE, maxE = minimum(E), maximum(E)
	Ei = round(Integer, min(N_COLORS, max(1, (round(Integer, 1 .+ N_COLORS .* (E .- minE)/(maxE - minE))))))

	Ei[plan .== 0] = N_COLORS;

	field = Array(Float64, (size(Ei)[1], size(Ei)[2], 3))
	field[:,:,1] = [ cm[ei].r for ei in Ei ]
	field[:,:,2] = [ cm[ei].g for ei in Ei ]
	field[:,:,3] = [ cm[ei].b for ei in Ei ]

	fim = Images.colorim(permutedims(field, [2, 1, 3]))
	Images.imwrite(fim, "figs/pltest.png")
end

main()
