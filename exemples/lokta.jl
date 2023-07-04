using ModelingToolkit
using DifferentialEquations

#variables and parameters of the model (the variable/parameter name "t" is forbiden)
@variables t
D = Differential(t)
@parameters prey_death_proportionality_constant = 0.02
@parameters prey_birth_fraction = 2.0
@parameters predator_birth_fraction = 0.01
@parameters predator_death_proportionality_constant = 1.05
@variables Predator_Population(t) = 15.0
@variables Prey_Population(t) = 100.0
@variables predator_births(t)
@variables predator_deaths(t)
@variables prey_births(t)
@variables prey_deaths(t)

    
#définition des equations:
eqs = [
    D(Predator_Population) ~ predator_births-predator_deaths
    D(Prey_Population) ~ prey_births-prey_deaths
    predator_births ~ ((predator_birth_fraction)*(Prey_Population))*(Predator_Population)
    predator_deaths ~ (predator_death_proportionality_constant)*(Predator_Population)
    prey_births ~ (prey_birth_fraction)*(Prey_Population)
    prey_deaths ~ ((prey_death_proportionality_constant)*(Predator_Population))*(Prey_Population)
]

#il faut maintenant définir le solveur:

@named sys= ODESystem(eqs)
sys= structural_simplify(sys)
prob= ODEProblem(sys,[],(0,12))
solved=solve(prob)
using Plots

plot(solved)