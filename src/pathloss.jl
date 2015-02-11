using Color
using Images

const INFILE = "resources/floorplan-wf.png"
const N_COLORS = 10

const TX_POS    = 870, 425
const TX_POS_IM = 870 + 425im

img = imread(INFILE)
plan = reinterpret(Uint8, data(img));

dimx, dimy = size(plan)

Dist = similar(plan, Float64)

for x in 1:dimx, y in 1:dimy
	Dist[x,y] = 0.2*abs(x+y*im - TX_POS_IM)
end

Dist[TX_POS...] = Dist[TX_POS[1]-1, TX_POS[2]-1]

E = similar(Dist, Float64)
E = 20 .* log10(Dist .^ -2)

E[E .< -90] = -90

cm = reverse(colormap("blues", N_COLORS))
Ei = round(Integer, min(N_COLORS, max(1, (int(1 .+ N_COLORS .* (E .- minimum(E))/(maximum(E) - minimum(E)))))))

Ei[plan .== 0x00] = N_COLORS;   # draw the walls

field = Array(Float64, (size(Ei)[1], size(Ei)[2], 3))
field[:,:,1] = [ cm[ei].r for ei in Ei ]
field[:,:,2] = [ cm[ei].g for ei in Ei ]
field[:,:,3] = [ cm[ei].b for ei in Ei ]

fim = colorim(permutedims(field, [2, 1, 3]))
imwrite(fim, "figs/pltest.png")
