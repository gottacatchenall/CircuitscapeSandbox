from Circuitscape import *

install()  # this only has to be run once


cs = CircuitscapeInterface()

# the first time this is run it will be slow due to julia precompilation, but
# subsequent runs will be faster
batch = cs.run(
    batch_size = 32,
    explore_score=0.5,
    number_of_patches = 5,
    raster_dimensions = (64, 64),
)


idx = 1
batch.runs[idx].plot()
