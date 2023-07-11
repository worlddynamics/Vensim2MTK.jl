using ModelingToolkit, DifferentialEquations

@variables t
D = Differential(t)

@variables f(t) g(t)

eqs = [D(f) ~ g - f, g ~ t]

@named sys = ODESystem(eqs)
sys = structural_simplify(sys)
prob = ODEProblem(sys, [f => g, g => 10], (0.0, 10.0))
sol = solve(prob)