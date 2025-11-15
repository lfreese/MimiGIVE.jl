using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# Auto-accept data dependency downloads
ENV["DATADEPS_ALWAYS_ACCEPT"] = "true"

using Mimi, DataFrames, Query, CSV
using MimiGIVE

println("Testing FAIR temperature method...")

println("\n=== Test 1: FAIR Temperature Method ===")
try
    println("Creating FAIR model...")
    m_fair = MimiGIVE.get_model(temperature_method = :fair)
    
    println("Model created successfully")
    println("Running FAIR model...")
    run(m_fair)
    println("✓ FAIR model successful!")
    
catch e
    println("✗ FAIR model failed: $e")
    println("Error type: $(typeof(e))")
    
    # Print the full stack trace
    println("\nFull stack trace:")
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end

println("\n=== Summary ===")
println("Tested FAIR temperature method.")