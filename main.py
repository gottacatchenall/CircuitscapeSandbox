
from Circuitscape import *

cs = CircuitscapeInterface() # this will error the first time --- thats okay
cs.install()  # this only has to be run once, and then the above line will work 

# the first time this is run it will be slow due to julia precompilation, but
# subsequent runs will be faster
outdir = cs.run(
    batch_size = 128,
    number_of_patches = 5,
    raster_dimensions = (32, 32),
)
