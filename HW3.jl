using JuMP
using Cbc

# Define the locations (plants) and zones
locations = ["Chicago", "Princeton, NJ", "Atlanta", "LA"]
zones = ["Northwest", "Southwest", "Upper Midwest", "Lower Midwest", "Northeast", "Southeast"]

# Define fixed costs, variable costs per unit, and capacities for wipes and ointment
fixed_costs_wipes = [5000, 2200, 2200, 2200]
variable_costs_wipes = [10, 10, 10, 10]
capacities_wipes = [5000, 2000, 2000, 2000]
fixed_costs_ointment = [1500, 1500, 1500, 1500]
variable_costs_ointment = [20, 20, 20, 20]
capacities_ointment = [1000, 1000, 1000, 1000]

# Define regional demand for wipes and ointment
demand_wipes = [500, 700, 900, 800, 1000, 600]
demand_ointment = [50, 90, 120, 65, 120, 70]

# Define transportation costs
transportation_costs = Dict(
    "Chicago" => Dict(zip(zones, [6.32, 6.32, 3.68, 4.04, 5.76, 5.96])),
    "Princeton, NJ" => Dict(zip(zones, [6.60, 6.60, 5.76, 5.92, 3.68, 4.08])),
    "Atlanta" => Dict(zip(zones, [6.72, 6.48, 5.92, 4.08, 4.04, 3.64])),
    "LA" => Dict(zip(zones, [4.36, 3.68, 6.32, 6.32, 6.72, 6.60]))
)

# Create a JuMP model
model = Model(Cbc.Optimizer)
rows = 4
cols = 6

# Create a 2D array to store decision variables
# Define decision variables for wipes and ointment flow
@variable(model, 0 <= wipes_flow[i=1:rows, j=1:cols] <= capacities_wipes[i])
@variable(model, 0 <= ointment_flow[i=1:rows, j=1:cols] <= capacities_ointment[i])

# Calculate the objective value
objective_value = 
    sum(fixed_costs_wipes[i] + sum(variable_costs_wipes[i] * wipes_flow[i, j] for j in 1:6) for i in 1:4) +
    sum(fixed_costs_ointment[i] + sum(variable_costs_ointment[i] * ointment_flow[i, j] for j in 1:6) for i in 1:4) +
    sum(transportation_costs[city_name][zone_name] * (wipes_flow[i, j] + ointment_flow[i, j]) for city_name in locations, zone_name in zones for j in 1:6, i in 1:4)

# Define objective function to minimize total cost using the calculated value
@objective(model, Min, objective_value)


# Demand constraints for wipes and ointment
for j in 1:6
    @constraint(model, sum(wipes_flow[i, j] for i in 1:4) == demand_wipes[j])
    @constraint(model, sum(ointment_flow[i, j] for i in 1:4) == demand_ointment[j])
end

# Solve the optimization problem
print(model) 
status = JuMP.optimize!(model)

# Print results
if termination_status(model) == MOI.OPTIMAL
    println("Optimal Solution Found:")
    println("Objective Value (Total Cost): ", JuMP.objective_value(model))
    for i in 1:4
        for j in 1:6
            println("Flow from $(locations[i]) to $(zones[j]) - Wipes: ", value(wipes_flow[i, j]), ", Ointment: ", value(ointment_flow[i, j]))
        end
    end
else
    println("No optimal solution found.")
end
