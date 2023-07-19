# Vensim.jl 

This package provides a function `Vensim2MTK` that can produce a Julia file of a model using ModelingToolkit from an exported Vensim model.

Usage of the function: 
Vensim2MTK has 3 arguments:
- `filepath`: the path to the vensim file that one wants to translate. Default to ./examples/Dice.xmile
- `filename`: the name of the output file. default to the name of the input file with the extension `.jl` replacing `.xmile`
- `overwrite`: boolean argument that decide if filename already exist, if it aborts or overwrite (true to overwrite)


Example of use:
```julia
using Vensim

filepath="path/to/a/vensim/model/model.xmile"
filename="MTKmodel.jl"
overwrite = false
Vensim2MTK(filepath,filename,overwrite) 
```
This code will write in the file `MTKmodel.jl` an implementation in ModelingToolkit of the model exported in `model.xmile` from the Vensim app.




## Examples of models used

there are currently 4 models used as examples for the parser: 
DICE,lokta, commitment and community corona 8. Here is a quick explenation of each as well as where we found them: 

- `Dice` is the William Nordhaus’Dice model; the implementation of it was fount here: https://metasd.com/2010/06/dice/ and is the `DICE-heur-7-PLE.mdl` version (as Vensim has some issues with exporting some models as xmile files, some version of the models used may not works. usually, the .mdl works with no issue)

-`lokta` is the simple lokta-voltera predation model, found here:http://www.shodor.org/refdesk/BioPortal/model/VSpredatorPrey?level=advanced

-`commitment` is a model thats based on an Arxiv paper (https://doi.org/10.48550/arXiv.1209.3546). the model was published on this blog post:https://metasd.com/2012/09/encouraging-moderation/

-`community corona 8` is a model representing the evolution of the coronavirus in a community, and the effectivness of some method. See this blog post: https://metasd.com/2020/03/community-coronavirus-model-bozeman/
## List of Vensim functions currently implemented:

- `if_then_else`
- `EXP` 
- `LOG`
- `GAME`(will not cause an error but not implemented, as there is no interactive mode yet)
- `SMOOTH`
- `SMOOTHi`
- `STEP`
- `MAX`
- `MIN`
- `LN`
- `ABS`
- `COS`
- `ARCCOS`
- `SIN`
- `ARCSIN`
- `TAN`
- `ARCTAN`
- `GAMMA_LN`
- `MODULO`
- `SMOOTH3`
- `PULSE`
- `RAMP`
- `SMOOTH3i`
- `DELAY1`
- `DELAY1I`
