using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# Auto-accept data dependency downloads
ENV["DATADEPS_ALWAYS_ACCEPT"] = "true"

using Mimi, DataFrames, Query, CSV, Statistics

# the local MimiGIVE since it's already activated
using MimiGIVE

println("\n" * "="^80)
println("COMPARING THREE TEMPERATURE METHODS")
println("="^80)

# Create output directory
output_dir = joinpath(@__DIR__, "..", "output", "method_comparison")
mkpath(output_dir)
println("\nResults will be saved to: $output_dir\n")

# Dictionary to store results
results = Dict()


# ============================================================================
# Test 1: FAIR Temperature Method
# ============================================================================
println("\n" * "="^80)
println("Test 1: FAIR Temperature Method")
println("="^80)

try
    println("Creating FAIR model...")
    m_fair = MimiGIVE.get_model(temperature_method = :fair)
    
    println("Running FAIR model...")
    run(m_fair)
    println("✓ FAIR model successful!")
    
    # Extract key outputs
    println("\nExtracting FAIR outputs...")
    
    # Global temperature from FAIR temperature component
    global_temp_fair = m_fair[:temperature, :T]
    
    # Mortality costs
    mortality_fair = getdataframe(m_fair, :CromarMortality, :mortality_costs)
    
    # Ocean heat content
    del_ohc_fair = m_fair[:temperature, :del_ohc]
    
    # Store results
    results[:fair] = Dict(
        :global_temp => global_temp_fair,
        :mortality => mortality_fair,
        :del_ohc => del_ohc_fair
    )
    
    # Save to CSV
    df_global_temp = DataFrame(time = 1750:2300, global_temperature = global_temp_fair)
    CSV.write(joinpath(output_dir, "fair_global_temperature.csv"), df_global_temp)
    CSV.write(joinpath(output_dir, "fair_mortality_costs.csv"), mortality_fair)
    println("  Saved FAIR outputs")
    
    # Print statistics
    println("\nFAIR Temperature Statistics:")
    println("  Global temp min: $(minimum(skipmissing(global_temp_fair)))")
    println("  Global temp max: $(maximum(skipmissing(global_temp_fair)))")
    println("  Global temp 2020: $(global_temp_fair[271])")
    
catch e
    println("✗ FAIR model failed: $e")
    showerror(stdout, e, catch_backtrace())
end

# ============================================================================
# Test 2: Pattern Scaling Method
# ============================================================================
println("\n\n" * "="^80)
println("Test 2: Pattern Scaling Method")
println("="^80)

try
    println("Creating Pattern Scaling model...")
    m_ps = MimiGIVE.get_model(temperature_method = :pattern_scaling)
    
    println("Running Pattern Scaling model...")
    run(m_ps)
    println("✓ Pattern Scaling model successful!")
    
    # Extract key outputs
    println("\nExtracting Pattern Scaling outputs...")
    
    # Global temperature
    global_temp_ps = m_ps[:temperature, :T]
    
    # Local temperature
    local_temp_ps = m_ps[:TempMortality_PatternScaling, :local_temperature]
    
    # Mortality costs
    mortality_ps = getdataframe(m_ps, :CromarMortality, :mortality_costs)
    
    # Ocean heat content
    del_ohc_ps = m_ps[:temperature, :del_ohc]
    
    # Store results
    results[:pattern_scaling] = Dict(
        :global_temp => global_temp_ps,
        :local_temp => local_temp_ps,
        :mortality => mortality_ps,
        :del_ohc => del_ohc_ps
    )
    
    # Save to CSV
    df_global_temp = DataFrame(time = 1750:2300, global_temperature = global_temp_ps)
    CSV.write(joinpath(output_dir, "pattern_scaling_global_temperature.csv"), df_global_temp)
    CSV.write(joinpath(output_dir, "pattern_scaling_mortality_costs.csv"), mortality_ps)
    println("  Saved Pattern Scaling outputs")
    
    # Print statistics
    println("\nPattern Scaling Temperature Statistics:")
    println("  Global temp min: $(minimum(skipmissing(global_temp_ps)))")
    println("  Global temp max: $(maximum(skipmissing(global_temp_ps)))")
    println("  Global temp 2020: $(global_temp_ps[271])")
    
catch e
    println("✗ Pattern Scaling model failed: $e")
    showerror(stdout, e, catch_backtrace())
end

# ============================================================================
# Test 3: Green's Functions Method
# ============================================================================
println("\n\n" * "="^80)
println("Test 3: Green's Functions Method")
println("="^80)

try
    println("Creating Green's Functions model...")
    m_gf = MimiGIVE.get_model(temperature_method = :greens_function)
    
    println("Running Green's Functions model...")
    run(m_gf)
    println("✓ Green's Functions model successful!")
    
    # Extract key outputs
    println("\nExtracting Green's Functions outputs...")
    
    # Global temperature
    global_temp_gf = m_gf[:TempMortality_GreensFunction, :global_temperature]
    
    # Local temperature
    local_temp_gf = m_gf[:TempMortality_GreensFunction, :local_temperature]
    
    # Mortality costs
    mortality_gf = getdataframe(m_gf, :CromarMortality, :mortality_costs)
    
    # Ocean heat content
    del_ohc_gf = m_gf[:OceanHeatAccumulator, :del_ohc]
    
    # Store results
    results[:greens_function] = Dict(
        :global_temp => global_temp_gf,
        :local_temp => local_temp_gf,
        :mortality => mortality_gf,
        :del_ohc => del_ohc_gf
    )
    
    # Save to CSV
    df_global_temp = DataFrame(time = 1750:2300, global_temperature = global_temp_gf)
    CSV.write(joinpath(output_dir, "greens_function_global_temperature.csv"), df_global_temp)
    CSV.write(joinpath(output_dir, "greens_function_mortality_costs.csv"), mortality_gf)
    println("  Saved Green's Functions outputs")
    
    # Print statistics
    println("\nGreen's Functions Temperature Statistics:")
    println("  Global temp min: $(minimum(skipmissing(global_temp_gf)))")
    println("  Global temp max: $(maximum(skipmissing(global_temp_gf)))")
    println("  Global temp 2020: $(global_temp_gf[271])")
    
catch e
    println("✗ Green's Functions model failed: $e")
    showerror(stdout, e, catch_backtrace())
end

# ============================================================================
# Comparison Analysis
# ============================================================================
println("\n\n" * "="^80)
println("COMPARISON ANALYSIS")
println("="^80)

if haskey(results, :fair) && haskey(results, :pattern_scaling) && haskey(results, :greens_function)
    println("\nAll three methods completed successfully!")
    
    # Compare global temperatures at key years
    println("\n" * "-"^80)
    println("Global Temperature Comparison (°C)")
    println("-"^80)
    
    key_years = [1750, 1850, 1900, 1950, 2000, 2020, 2050, 2100, 2200, 2300]
    
    df_comparison = DataFrame(
        Year = key_years,
        FAIR = [results[:fair][:global_temp][y - 1750 + 1] for y in key_years],
        PatternScaling = [results[:pattern_scaling][:global_temp][y - 1750 + 1] for y in key_years],
        GreensFunction = [results[:greens_function][:global_temp][y - 1750 + 1] for y in key_years]
    )
    
    # Add differences
    df_comparison.FAIR_vs_PS = df_comparison.FAIR .- df_comparison.PatternScaling
    df_comparison.FAIR_vs_GF = df_comparison.FAIR .- df_comparison.GreensFunction
    df_comparison.PS_vs_GF = df_comparison.PatternScaling .- df_comparison.GreensFunction
    
    println(df_comparison)
    CSV.write(joinpath(output_dir, "temperature_comparison.csv"), df_comparison)
    
    # Compare total mortality costs by year
    println("\n" * "-"^80)
    println("Total Mortality Costs Comparison (2020-2030)")
    println("-"^80)
    
    # Aggregate mortality costs by year for each method
    mort_fair = results[:fair][:mortality] |> 
        @groupby(_.time) |> 
        @map({time=key(_), total_cost=sum(_.mortality_costs)}) |> 
        DataFrame |>
        @filter(_.time >= 2020 && _.time <= 2030) |>
        DataFrame
    
    mort_ps = results[:pattern_scaling][:mortality] |> 
        @groupby(_.time) |> 
        @map({time=key(_), total_cost=sum(_.mortality_costs)}) |> 
        DataFrame |>
        @filter(_.time >= 2020 && _.time <= 2030) |>
        DataFrame
    
    mort_gf = results[:greens_function][:mortality] |> 
        @groupby(_.time) |> 
        @map({time=key(_), total_cost=sum(_.mortality_costs)}) |> 
        DataFrame |>
        @filter(_.time >= 2020 && _.time <= 2030) |>
        DataFrame
    
    df_mort_comparison = DataFrame(
        Year = mort_fair.time,
        FAIR = mort_fair.total_cost,
        PatternScaling = mort_ps.total_cost,
        GreensFunction = mort_gf.total_cost
    )
    
    println(df_mort_comparison)
    CSV.write(joinpath(output_dir, "mortality_comparison.csv"), df_mort_comparison)
    
    # Summary statistics
    println("\n" * "-"^80)
    println("Summary Statistics (2020-2100)")
    println("-"^80)
    
    idx_2020 = 271  # 2020 - 1750 + 1
    idx_2100 = 351  # 2100 - 1750 + 1
    
    println("\nMean Global Temperature 2020-2100:")
    println("  FAIR:            $(mean(results[:fair][:global_temp][idx_2020:idx_2100])) °C")
    println("  Pattern Scaling: $(mean(results[:pattern_scaling][:global_temp][idx_2020:idx_2100])) °C")
    println("  Green's Function: $(mean(results[:greens_function][:global_temp][idx_2020:idx_2100])) °C")
    
    println("\nTotal Mortality Costs 2020-2100:")
    mort_fair_sum = mort_fair |> @filter(_.time <= 2100) |> @map(_.total_cost) |> sum
    mort_ps_sum = mort_ps |> @filter(_.time <= 2100) |> @map(_.total_cost) |> sum
    mort_gf_sum = mort_gf |> @filter(_.time <= 2100) |> @map(_.total_cost) |> sum
    
    println("  FAIR:            \$$(mort_fair_sum / 1e12) trillion")
    println("  Pattern Scaling: \$$(mort_ps_sum / 1e12) trillion")
    println("  Green's Function: \$$(mort_gf_sum / 1e12) trillion")
    
else
    println("\nNot all methods completed successfully. Cannot perform comparison.")
end

println("\n" * "="^80)
println("ANALYSIS COMPLETE")
println("="^80)
println("\nAll results saved to: $output_dir")
println("\nKey output files:")
println("  - temperature_comparison.csv")
println("  - mortality_comparison.csv")
println("  - [method]_global_temperature.csv")
println("  - [method]_mortality_costs.csv")