# Vensim.jl 

The file "model_translation" contain the function "simple_file_writer" that will print the string of the translated model. 
to use it, there is a need to change the filepath variable into the file path to the .xmile one want to parse. 
NB: it is important that for the models containing no tables, one must be manually added after the equations definition and before the parameters, so that the parser can separate the information correctly.

2 example xmile file are provided: 
- `Lokta.xmile`, a simple prey predation model; and `lokta.jl`, the resulting string when executing the file.
- `Dice.xmile`, the model Dice, and the resulting string in `Dice.jl` (WIP).
