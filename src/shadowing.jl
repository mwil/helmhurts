using Color
using Images

const INFILE = "resources/plan.png"
const N_COLORS = 100

const TX_POS = 150, 150

function line(x0::Int, y0::Int, x1::Int, y1::Int)
	result = Array((Int,Int), 0)
	rev = identity

	if abs(y1-y0) ≤ abs(x1-x0)
		x0, y0, x1, y1 = y0, x0, y1, x1
		rev = reverse
	end

	if x1<x0
		x0, y0, x1, y1 = x1, y1, x0, y0
	end

	leny = abs(y1 - y0)

	for i in 0:leny
		push!(result, rev((round(Int, i//leny * (x1-x0) + x0), (y1>y0? 1 : -1)*i + y0)))
	end

	return result
end

function dist(x::Int, y::Int)
	return sqrt((TX_POS[1]-x)^2 + (TX_POS[2]-y)^2) * 0.2
end

function pathloss(x::Int, y::Int)
	return 20*log10(dist(x,y)^-2)
end

function shadowing(x::Int, y::Int, plan)
	pixels = line(x,y, TX_POS[1],TX_POS[2])
	concrete = 0

	for pixel in pixels
		concrete += plan[pixel...] ≠ 255? 1: 0
	end

	return 20*log10(concrete*2)
end

img = imread(INFILE)
plan = reinterpret(Uint8, data(img));

dimx, dimy = size(plan)

E = similar(plan, Float64)

for x in 1:dimx, y in 1:dimy
	if (x,y) == TX_POS
		E[x,y] = pathloss(x-1, y-1) - shadowing(x-1, y-1, plan)
	else
		E[x,y] = pathloss(x,y) - shadowing(x,y,plan)
	end
end

#E[E .< -90] = -90

cm = reverse(colormap("blues", N_COLORS))
minE = minimum(E)
maxE = maximum(E)
Ei = round(Integer, min(N_COLORS, max(1, (round(Integer, 1 .+ N_COLORS .* (E .- minE)/(maxEi - minE))))))

img = imread(INFILE)
plan = reinterpret(Uint8, data(img));
Ei[plan .== 0] = N_COLORS;

field = Array(Float64, (size(Ei)[1], size(Ei)[2], 3))
field[:,:,1] = [ cm[ei].r for ei in Ei ]
field[:,:,2] = [ cm[ei].g for ei in Ei ]
field[:,:,3] = [ cm[ei].b for ei in Ei ]

fim = colorim(permutedims(field, [2, 1, 3]))
imwrite(fim, "figs/shtest.png")
