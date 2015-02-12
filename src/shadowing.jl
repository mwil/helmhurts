import Color
import Images

const INFILE = "resources/floorplan-wf.png"
const N_COLORS = 20

const TX_POS = 870, 425

@doc doc"""
Find the pixels on a straight line from (x0,y0) to (x1,y1).
Returns a list of (x,y) tuples, including start and end points."""
function line(x0::Int, y0::Int, x1::Int, y1::Int)
	result = Array((Int,Int), 0)
	rev = identity

	if abs(y1-y0) ≤ abs(x1-x0)
		x0, y0, x1, y1 = y0, x0, y1, x1
		rev = reverse
	end

	leny = abs(y1 - y0)

	for i in 0:leny
		push!(result, rev((round(Int, i//leny * (x1-x0) + x0), (y1>y0? 1 : -1)*i + y0)))
	end

	return result
end

@doc doc"""
For each pixel on the floor plan, find the number of wall pixels towards the signal source
and reduce the received signal strength by a certain factor.

Parameters:
	`plan`:         a floor plan with white pixels signifying air, the rest are interpreted as walls.
	`dB_per_pixel`: regulates the amount of fading that is induced by a single wall pixel."""
function shadowing(plan; dB_per_pixel=0.1)
	S = zeros(Float64, size(plan)...) .- 1.0
	dimx, dimy = size(S)

	# count the number of pixels that are non-white (walls)
	for x in 1:dimx, y in 1:dimy
		if S[x,y] < 0.0
			pixels = line(TX_POS[1],TX_POS[2], x,y)
			wallcnt = 0.0

			for pixel in pixels
				wallcnt += (plan[pixel...]≠0xff)? 1.0: 0.0
				S[pixel...] = wallcnt
			end
		end
	end

	S[S.> 0.0] = S[S.>0.0] * dB_per_pixel
	S[S.<=0.0] = 0.0

	return S
end

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
	S =  shadowing(plan)
	E = PL .- S

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
	Images.imwrite(fim, "figs/shtest.png")
end

main()
