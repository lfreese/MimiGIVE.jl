using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# Auto-accept data dependency downloads
ENV["DATADEPS_ALWAYS_ACCEPT"] = "true"

using Mimi, DataFrames, Query, CSV

# the local MimiGIVE since it's already activated
using MimiGIVE

println("\nTesting all three temperature methods...")

# Test 3: Green's Functions
println("\n=== Test 3: Green's Functions Method ===")
println("Creating Green's functions model...")
println("DEBUG: About to call get_model with :greens_function")

try
    println("Creating Green's functions model...")
    println("DEBUG: About to call get_model with :greens_function")
    flush(stdout)  # Ensure output is shown immediately
    
    m_gf = MimiGIVE.get_model(temperature_method = :greens_function)
    
    # Fixed debug lines - use Mimi.first_period
    println("\nDEBUG: Checking component timesteps...")
    println("  TempMortality_GreensFunction first: ", Mimi.first_period(Mimi.compdef(m_gf, :TempMortality_GreensFunction)))
    println("  OceanHeatAccumulator first: ", Mimi.first_period(Mimi.compdef(m_gf, :OceanHeatAccumulator)))
    println("  antarctic_icesheet first: ", Mimi.first_period(Mimi.compdef(m_gf, :antarctic_icesheet)))
    println("  global_sea_level first: ", Mimi.first_period(Mimi.compdef(m_gf, :global_sea_level)))

    println("DEBUG: Model created successfully, about to run...")
    flush(stdout)

    # Check parameter connections
    println("\nDEBUG: Checking parameter connections...")
    try
        gsl_conn = Mimi.get_connection(m_gf.md, :antarctic_icesheet, :global_sea_level)
        println("  antarctic_icesheet.global_sea_level connected to: ", gsl_conn)
    catch e
        println("  Cannot get connection info: $e")
    end
    
    println("Running Green's functions model...")
    run(m_gf)
    println("✓ Green's functions model successful!")
    
    # Try to get output
    try
        df_gf = getdataframe(m_gf, :CromarMortality, :mortality_costs) |> @filter(_.time >= 2020) |> DataFrame
        println("Green's functions mortality costs sample:")
        println(first(df_gf, 3))
    catch e
        println("Could not extract Green's functions data: $e")
        println("DEBUG: Error details: $(typeof(e))")
        println("DEBUG: Stack trace:")
        for (exc, bt) in Base.catch_stack()
            showerror(stdout, exc, bt)
            println()
        end
    end
    
catch e
    println("✗ Green's functions failed: $e")
    println("DEBUG: Error type: $(typeof(e))")
    
    # Print full stack trace for debugging
    println("DEBUG: Full stack trace:")
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
    
    # Try to get more specific error information
    if isa(e, MethodError)
        println("DEBUG: MethodError details:")
        println("  Function: $(e.f)")
        println("  Arguments: $(e.args)")
        println("  Argument types: $(typeof.(e.args))")
    end
end

println("\n=== Summary ===")
println("Tested all three temperature methods.")