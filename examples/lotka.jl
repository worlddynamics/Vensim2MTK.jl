using IfElse
using SpecialFunctions
using ModelingToolkit
using DifferentialEquations
using DataInterpolations

@variables t
D = Differential(t)
@parameters TIME_STEP=0.03125 [description = "TIME_STEP, the dt of the model"]
     @variables t_plus(t) = TIME_STEP/2 [description= "t_plus, variable used for pulse to avoid rounding errors"]
@parameters prey_death_proportionality_constant = 0.02 [description = "prey_death_proportionality_constant"]
@parameters prey_birth_fraction = 2.0 [description = "prey_birth_fraction"]
@parameters predator_birth_fraction = 0.01 [description = "predator_birth_fraction"]
@parameters predator_death_proportionality_constant = 1.05 [description = "predator_death_proportionality_constant"]
@variables Predator_Population(t) = 15 [description = "Predator_Population"]
@variables Prey_Population(t) = 100 [description = "Prey_Population"]
@variables predator_births(t)  [description = "predator_births"]
@variables predator_deaths(t)  [description = "predator_deaths"]
@variables prey_births(t)  [description = "prey_births"]
@variables prey_deaths(t)  [description = "prey_deaths"]

    eqs = [
        t_plus ~ t + (TIME_STEP / 2)
    	D(Predator_Population) ~ predator_births - predator_deaths
	D(Prey_Population) ~ prey_births - prey_deaths
	predator_births ~ ((predator_birth_fraction) * (Prey_Population)) * (Predator_Population)
	predator_deaths ~ (predator_death_proportionality_constant) * (Predator_Population)
	prey_births ~ (prey_birth_fraction) * (Prey_Population)
	prey_deaths ~ ((prey_death_proportionality_constant) * (Predator_Population)) * (Prey_Population)
]
     
     
 @named sys= ODESystem(eqs)
 sys= structural_simplify(sys)
 prob= ODEProblem(sys,[],(0,12), solver=RK4, dt=0.03125, dtmax=0.03125)
                     solved=solve(prob)
                         