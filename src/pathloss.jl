using Color
using Images

const INFILE = "resources/floorplan-wf.png"

const TX_POS = 870, 425

dist(x,y) = sqrt((TX_POS[1]-x)^2 + (TX_POS[2]-y)^2) * 0.2

img = imread(INFILE)
plan = reinterpret(Uint8, data(img));

dimx, dimy = size(plan)

E = similar(plan, Float64)

for x in 1:dimx, y in 1:dimy
	if (x,y) == TX_POS
		E[x,y] = 20*log10(dist(x-1,y-1)^-2)
	else
		E[x,y] = 20*log10(dist(x,y)^-2)
	end
end

#E[E .< -90] = -90

cm = reverse(colormap("blues", 10))
Ei = round(Integer, min(10, max(1, (int(1 .+ 10 .* (E .- minimum(E))/(maximum(E) - minimum(E)))))))

img = imread(INFILE)
plan = reinterpret(Uint8, data(img));
Ei[plan .== 0] = 10;

field = Array(Float64, (size(Ei)[1], size(Ei)[2], 3))
field[:,:,1] = [ cm[ei].r for ei in Ei ]
field[:,:,2] = [ cm[ei].g for ei in Ei ]
field[:,:,3] = [ cm[ei].b for ei in Ei ]

fim = colorim(permutedims(field, [2, 1, 3]))
imwrite(fim, "figs/pltest.png")
