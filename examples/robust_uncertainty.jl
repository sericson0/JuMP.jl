#############################################################################
# JuMP
# An algebraic modeling langauge for Julia
# See http://github.com/JuliaOpt/JuMP.jl
#############################################################################
# robust_uncertainty.jl
#
# Computes the Value at Risk for a data-driven uncertainty set; see
# "Data-Driven Robust Optimization" (Bertsimas 2013), section 6.1 for
# details. Closed-form expressions for the optimal value are available.
#############################################################################


using JuMP, SCS, LinearAlgebra

R = 1
d = 3
𝛿 = 0.05
ɛ = 0.05
N = ceil((2+2log(2/𝛿))^2) + 1

Γ1(𝛿,N) = (R/sqrt(N))*(2+sqrt(2*log(1/𝛿)))
Γ2(𝛿,N) = (2R^2/sqrt(N))*(2+sqrt(2*log(2/𝛿)))

μhat = rand(d)
M = rand(d,d)
Σhat = 1/(d-1)*(M-ones(d)*μhat')'*(M-ones(d)*μhat')

m = Model(with_optimizer(SCS.Optimizer))

@variable(m, Σ[1:d, 1:d], PSD)
@variable(m, u[1:d])
@variable(m, μ[1:d])

@constraint(m, [Γ1(𝛿/2,N);      μ-μhat] in SecondOrderCone())
@constraint(m, [Γ2(𝛿/2,N); vec(Σ-Σhat)] in SecondOrderCone())

A = [(1-ɛ)/ɛ (u-μ)';
     (u-μ)     Σ   ]
@SDconstraint(m, A >= 0)

c = randn(d)
@objective(m, Max, dot(c,u))

JuMP.optimize!(m)

object = JuMP.objective_value(m)
exact = dot(μhat,c) + Γ1(𝛿/2,N)*norm(c) + sqrt((1-ɛ)/ɛ)*sqrt(dot(c,(Σhat+Γ2(𝛿/2,N)*Matrix(1.0I,d,d))*c))

println("objective value:  $(object)")
println("error from exact: $(abs(exact-object))")
