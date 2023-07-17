# Vensim.jl 

This package provides a function "Vensim2MTK" that can produce a Julia file of a model using ModelingToolkit from an exported Vensim model.

Usage of the function: 
Vensim2MTK has 3 arguments:
-filepath: the path to the vensim file that one wants to translate. Default to ./examples/Dice.xmile
-filename: the name of the output file. default to the name of the inputfile with the extension ".jl" replacing ".xmile"
-overwrite: boolean argument that decide if filename already exist, if it aborts or overwrite (true to overwrite)

example: 

Vensim.Vensim2MTK("path/to/a/vensim/model/model.xmile","MTKmodel",false) 

Will take the model in model.xmile file and create the file MTKmodel.jl containing the model translated in ModelingToolkit(except if a file MTKmodel.jl already exists) 

Current limitations: 

-For a correct information handling, it is necessary to have a table in the model. that table can be blank.  
list of Vensim functions currently implemented:

"EXP"
"LOG"
"GAME"(will not cause an error but not implemented, as there is no interactive mode yet
"IFTHENELSE"
"SMOOTH"
"SMOOTHi"
"STEP"
"MAX"
"MIN"
"LN"
"ABS"
"COS"
"ARCCOS"
"SIN"
"ARCSIN"
"TAN"
"ARCTAN"
"GAMMA_LN"
"MODULO"
"SMOOTH3"
"PULSE
