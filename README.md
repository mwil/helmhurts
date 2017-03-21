# helmhurts
This code can be used to produce figures of wireless propagation effects in indoor scenarios, especially using the Helmholtz equation to model the amplitude field of wireless propagation. Additionally, simple path loss and shadowing can be applied to PNG images showing a simplified black-and-white floorplan. 

The code can be extended to support different materials to see even more interesting effects. However, the ability to make accurate predictions on actual wireless behavior should be assumed to be non-existent for any practical purpose. 

This code is inspired by the [blog entry of Jason Cole](http://jasmcole.com/2014/08/25/helmhurts) that explains the idea and basically solves everything already. 

I initially started by using code from Frédéric Testard ([fredo-dedup](https://gist.github.com/fredo-dedup), [code preview using nbviewer](http://nbviewer.ipython.org/gist/fredo-dedup/31ae1b6017833e9a18f8)).

The code iterates naively over all pixels of a floorplan to count wall pixels for shadowing or inverts a giant matrix, so try to use a PNG floorplan with less pixels if you run into problems.

## How to Use
### Install Julia runtime
From http://julialang.org/ or from repository

### Install dependencies
```julia
julia -e 'Pkg.add("Color")'
julia -e 'Pkg.add("Images")'
```

### Create output folder figs
```bash
mkdir helmhurts/figs
julia src/helmhurts.jl
```

It use lot of RAM. For demo example about 10 GB due to the resolution of the provided image.


## Example Outputs
Some example figures produced by the current implementation.

### Path Loss
![Path loss](examples/ex-pathloss.png)

### Shadowing
![Shadowing](examples/ex-shadowing.png)

### Helmhurts
![Helmhurts](examples/ex-helmhurts.png)
