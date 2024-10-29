# README.md

First, make sure Julia is installed. 

Then install `juliacall`, `numpy`, and `matplotlib` into a python environment
however you prefer.


Then to install Julia dependencies from within Python run

```
from Circuitscape import *

cs = CircuitscapeInterface() # this will error the first time --- thats okay
cs.install()  # this only has to be run once, and then the above line will work 
```

Note that `cs.install()` only needs to be run the first time to install dependencies
