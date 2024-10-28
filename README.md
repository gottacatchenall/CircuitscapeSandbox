# README.md

First, make sure Julia is installed. 

Then install `juliacell`, `numpy`, and `matplotlib` into a python environment
however you prefer.


Then to install Julia dependencies from within Python run

```
import CircuitscapeInterface
# this will throw an error the first time, its fine
cs = CircuitscapeInterface()
cs.install()
```

Note that `cs.install()` only needs to be run the first time to install dependencies