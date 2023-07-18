# Vensim.jl 

This package provides a function "Vensim2MTK" that can produce a Julia file of a model using ModelingToolkit from an exported Vensim model.

Usage of the function: 
Vensim2MTK has 3 arguments:
- Filepath: the path to the vensim file that one wants to translate. Default to ./examples/Dice.xmile
- Filename: the name of the output file. default to the name of the input file with the extension ".jl" replacing ".xmile"
- Overwrite: boolean argument that decide if filename already exist, if it aborts or overwrite (true to overwrite)


Example of use:
```julia
using Vensim

Vensim.Vensim2MTK("path/to/a/vensim/model/model.xmile","MTKmodel.jl",false) 
```
This code will write in the file "MTKmodel.jl" an implementation in ModelingToolkit of the model exported in "model.xmile" from the Vensim app.


## List of Vensim functions currently implemented:

- "if_then_else"
- "EXP" 
- "LOG"
- "GAME"(will not cause an error but not implemented, as there is no interactive mode yet)
- "IFTHENELSE"
- "SMOOTH"
- "SMOOTHi"
- "STEP"
- "MAX"
- "MIN"
- "LN"
- "ABS"
- "COS"
- "ARCCOS"
- "SIN"
- "ARCSIN"
- "TAN"
- "ARCTAN"
- "GAMMA_LN"
- "MODULO"
- "SMOOTH3"
- "PULSE"
- "RAMP"
- "SMOOTH3i"
- "DELAY1"
- "DELAY1I"
