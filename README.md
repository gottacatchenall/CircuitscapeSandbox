# README.md

First, make sure Julia is installed. 

Then install `juliacall`, `numpy`, and `matplotlib` into a python environment
however you prefer.


Then to install Julia dependencies and run a test batch of Circuitscape, within
Python run

```
from Circuitscape import *

install()  # this only has to be run once

cs = CircuitscapeInterface() 

batch = run()
batch.runs[0].plot()
```

Note that `install()` only needs to be run the first time to install dependencies
