from juliacall import Pkg as pkg
from juliacall import Main as jl

class CircuitscapeBatch():
    def __init__(self, path):
        self.path = path
        #self.runs = []
        
class CircuitscapeRun():
    def _init__(self):
        pass 

class CircuitscapeInterface():
    def __init__(self):
        pkg.activate(".")
        self.interface = jl.include("circuitscape_interface.jl")
    # Only has to be run once
    def install(self):
        pkg.instantiate() 
    # Runs circuitscape
    def run(
        self,
        batch_size=64,
        number_of_patches = 5,
        raster_dimensions = (64, 64),
        proportion_patch_cover = 0.3,
        explore_score = 0.5,
        number_of_categories = 5,
        category_value_distribution_parameters = (1.5, 3), # Gamma(x,y)
        autocorrelation = 0.9,
    ):
        result_path = self.interface.run_circuitscape(
            batch_size=batch_size,
            number_of_patches = number_of_patches,
            raster_dimensions = raster_dimensions,
            proportion_patch_cover = proportion_patch_cover,
            explore_score = explore_score,
            number_of_categories = number_of_categories,
            category_value_distribution_parameters = category_value_distribution_parameters,
            autocorrelation = autocorrelation,
        )
        return CircuitscapeBatch(result_path)


