from juliacall import Pkg as pkg
from juliacall import Main as jl
import os
import numpy as np
import matplotlib.pyplot as plt

# Only has to be run once
def install():
    pkg.activate(".")
    pkg.instantiate() 


def read_cs_output_raster(path):
    HEADERLINES = 6
    with open(path, 'r') as f:
        lines = f.readlines()[HEADERLINES:]
        matrix = []
        for line in lines:
            row = [float(x) for x in line.split()]
            matrix.append(row)
        return np.array(matrix)

def read_resistance_matrix(path):
    return np.loadtxt(path)[1:,1:]

def remove_patches(cumulative_current, patches):
    indices = np.where(~np.isnan(patches))
    cumulative_current[indices] = 0
    return cumulative_current

class CircuitscapeRun():
    def __init__(self, path):
        self.path = path         
        self.patches = read_cs_output_raster(os.path.join(path, "patches.txt"))  
        self.cumulative_current = remove_patches(read_cs_output_raster(os.path.join(path, "output_cum_curmap.asc")), self.patches) 
        self.resistance = read_cs_output_raster(os.path.join(path, "resistance.txt"))
            
        resistance_matrix = read_resistance_matrix(os.path.join(path, "output_resistances.out"))
        
        conductance_matrix = np.copy(resistance_matrix)
        conductance_matrix[conductance_matrix != 0] = 1 / conductance_matrix[conductance_matrix != 0]        
        self.conductance_matrix = conductance_matrix
        
    def plot(self):
        fig, axs = plt.subplots(ncols=2, nrows=2)
        axs[0,0].imshow(self.patches, origin='lower')
        axs[0,0].set_title("Patches")

        axs[1,0].imshow(self.resistance, origin='lower')
        axs[1,0].set_title("Resistance")


        axs[0,1].imshow(self.conductance_matrix)
        axs[0,1].set_title("Pairwise Conductance")

        axs[1,1].imshow(self.cumulative_current, origin='lower')
        axs[1,1].set_title("Cumulative Current Flow")
        plt.show()


class CircuitscapeBatch():
    def __init__(self, path):
        self.path = path
        self.runs = [CircuitscapeRun(os.path.join(path,x)) for x in os.listdir(path)]
        
class CircuitscapeInterface():
    def __init__(self):
        pkg.activate(".")
        self.interface = jl.include("circuitscape_interface.jl")
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


