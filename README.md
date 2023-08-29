# Vensim.jl 
[![DOI](https://zenodo.org/badge/662031882.svg)](https://zenodo.org/badge/latestdoi/662031882)

This package provides a function `Vensim2MTK` that can produce a Julia file of a model using ModelingToolkit from an exported Vensim model.

Usage of the function: 
The function takes 3 arguments:
- `filepath`: the path to the Vensim file that one wants to translate. Default to `./examples/Dice.xmile`.
- `filename`: the name of the output file. Default to the name of the input file with the extension `.jl` replacing `.xmile`.
- `overwrite`: boolean argument that indicate in the case of the file already existing, if the function aborts or overwrite it(true to overwrite).

Example of use:
```julia
using Vensim

filepath= "path/to/a/vensim/model/model.xmile"
filename= "MTKmodel.jl"
overwrite = false
Vensim2MTK(filepath, filename, overwrite) 
```
This code will write in the file `MTKmodel.jl` an implementation in ModelingToolkit of the model exported in `model.xmile` from the Vensim app.


## Examples of models used

There are currently 4 models used as examples for the parser: 
DICE, lokta, commitment and community corona 8. Here is a quick explanation of each as well as where we found them: 

- `Dice` is William Nordhaus’ Dice model; the implementation of it was found [here](https://metasd.com/2010/06/dice/) and is the `DICE-heur-7-PLE.mdl` version (as Vensim has some issues with exporting some models as xmile files, some version of the models used may not work. Usually, the .mdl works with no issue).

- `lokta` is the simple Lokta-Voltera predation model, found [here](http://www.shodor.org/refdesk/BioPortal/model/VSpredatorPrey?level=advanced).

- `commitment` is a model that is based on [an ArXiv paper](https://doi.org/10.48550/arXiv.1209.3546). The model was published on [this blog post](https://metasd.com/2012/09/encouraging-moderation/).

- `community corona 8` is a model representing the evolution of the coronavirus in a community, and the effectiveness of some method. See [this blog post](https://metasd.com/2020/03/community-coronavirus-model-bozeman/).


## List of Vensim functions currently implemented

- `if_then_else`
- `EXP` 
- `LOG`
- `GAME` (will not cause an error but not implemented, as there is no interactive mode yet)
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


## Issue #12 

If some variables need to be initialised by other variables that are not directly initialised, the program automatically initialises them with a default value (42). It is necessary to replace these with values that are at least not too far away from the real ones; just so that the model runs correctly without failing. It is then possible to obtain the true initial value and replace these arbitrary values with those calculated by ModelingToolkit; then re-run the model, obtaining from now on the real values for the whole model. 

## Issue #33 
It is necessary to make sure the model that is to be parsed does not contain special characters in it's variable name. the special characters mentioned are: 
`"`,`-`,`(`,`)`,`+`,`/`,`*`,`^`,`=`,`!`,`{`,`[`,`]`,`}` and `,`. 

## How to cite this work 
```
@software{emanuele_natale_vensim2mtk_2023,
  author       = {Emanuele Natale and
                  Maël Clergue},
  title        = {Vensim2MTK.jl: v0.1.0},
  month        = july,
  year         = 2023,
  publisher    = {Zenodo},
  version      = {v0.1.0},
  doi          = {10.5281/zenodo.8179079},
  url          = {https://doi.org/10.5281/zenodo.8179079}
}
```
