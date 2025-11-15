# using Pkg
# Pkg.activate(joinpath(@__DIR__, ".."))

# # Auto-accept data dependency downloads
# ENV["DATADEPS_ALWAYS_ACCEPT"] = "true"

# using Mimi, DataFrames, Query, CSV

# # the local MimiGIVE since it's already activated
# using MimiGIVE

# println("\nTesting all three temperature methods...")



# # Test 2: Pattern Scaling
# println("\n=== Test 2: Pattern Scaling Method ===")
# try
#     println("Creating pattern scaling model...")
#     m_ps = MimiGIVE.get_model(temperature_method = :pattern_scaling)
    
#     println("Running pattern scaling model...")
#     run(m_ps)
#     println("✓ Pattern scaling model successful!")
    
#     # Try to get output
#     try
#         df_ps = getdataframe(m_ps, :CromarMortality, :mortality_costs) |> @filter(_.time >= 2020) |> DataFrame
#         println("Pattern scaling mortality costs sample:")
#         println(first(df_ps, 3))
#     catch e
#         println("Could not extract pattern scaling data: $e")
#     end
    
# catch e
#     println("✗ Pattern scaling failed: $e")
# end


# println("\n=== Summary ===")
# println("Tested all three temperature methods.")


using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

# Auto-accept data dependency downloads
ENV["DATADEPS_ALWAYS_ACCEPT"] = "true"

using Mimi, DataFrames, Query, CSV, Statistics

# the local MimiGIVE since it's already activated
using MimiGIVE

println("\nTesting all three temperature methods...")

# Test 2: Pattern Scaling
println("\n=== Test 2: Pattern Scaling Method ===")
try
    println("Creating pattern scaling model...")
    m_ps = MimiGIVE.get_model(temperature_method = :pattern_scaling)
    
    println("Running pattern scaling model...")
    run(m_ps)
    println("✓ Pattern scaling model successful!")
    
    # Extract and examine temperature data
    println("\n=== Examining Pattern Scaling Temperature Output ===")
    
    # Get global temperature (it's a parameter in pattern scaling)
    global_temp = m_ps[:temperature, :T]  # From the temperature component
    println("\nGlobal temperature statistics:")
    println("  Min: $(minimum(skipmissing(global_temp)))")
    println("  Max: $(maximum(skipmissing(global_temp)))")
    println("  Mean: $(mean(skipmissing(global_temp)))")
    
    # Show sample of early, middle, and late values
    println("\nSample global temperature values:")
    println("  1750-1754: $(global_temp[1:5])")
    println("  1850-1854: $(global_temp[101:105])")
    println("  2020-2024: $(global_temp[271:275])")
    
    # Get local temperatures for first country
    local_temp = m_ps[:TempMortality_PatternScaling, :local_temperature]
    println("\nLocal temperature for country 1:")
    println("  1750-1754: $(local_temp[1:5, 1])")
    println("  1850-1854: $(local_temp[101:105, 1])")
    println("  2020-2024: $(local_temp[271:275, 1])")
    
    # === NEW: Check del_ohc values ===
    println("\n=== Examining Ocean Heat Content (del_ohc) ===")
    
    # Get del_ohc from temperature component (FAIR)
    del_ohc = m_ps[:temperature, :del_ohc]
    println("\ndel_ohc statistics:")
    println("  Min: $(minimum(skipmissing(del_ohc)))")
    println("  Max: $(maximum(skipmissing(del_ohc)))")
    println("  Mean: $(mean(skipmissing(del_ohc)))")
    
    # Show sample values at key years
    println("\nSample del_ohc values:")
    println("  1750-1754: $(del_ohc[1:5])")
    println("  1850-1854: $(del_ohc[101:105])")  # When BRICK starts
    println("  2020-2024: $(del_ohc[271:275])")
    
    # Get accumulated ocean heat from OceanHeatAccumulator
    println("\n=== Examining OceanHeatAccumulator Output ===")
    del_ohc_accum = m_ps[:OceanHeatAccumulator, :del_ohc_accum]
    println("\ndel_ohc_accum statistics (from 1850 onwards):")
    println("  Min: $(minimum(skipmissing(del_ohc_accum)))")
    println("  Max: $(maximum(skipmissing(del_ohc_accum)))")
    println("  Mean: $(mean(skipmissing(del_ohc_accum)))")
    
    # Show sample values
    println("\nSample del_ohc_accum values:")
    println("  1850-1854 (idx 1-5): $(del_ohc_accum[1:5])")
    println("  1900-1904 (idx 51-55): $(del_ohc_accum[51:55])")
    println("  2020-2024 (idx 171-175): $(del_ohc_accum[171:175])")
    
    # Check for extreme values in BRICK components
    println("\n=== Examining BRICK Component Inputs ===")
    
    # Antarctic ice sheet inputs
    ais_temp = m_ps[:antarctic_icesheet, :global_surface_temperature]
    println("\nAntarctic icesheet temperature input (from 1850):")
    println("  1850-1854: $(ais_temp[1:5])")
    println("  2020-2024: $(ais_temp[171:175])")
    
    ais_slr = m_ps[:antarctic_icesheet, :global_sea_level]
    println("\nAntarctic icesheet global_sea_level input (from 1850):")
    println("  1850-1854: $(ais_slr[1:5])")
    println("  2020-2024: $(ais_slr[171:175])")
    
    # Try to get mortality output
    try
        df_ps = getdataframe(m_ps, :CromarMortality, :mortality_costs) |> @filter(_.time >= 2020) |> DataFrame
        println("\n=== Pattern Scaling Mortality Costs Sample ===")
        println(first(df_ps, 3))
    catch e
        println("\nCould not extract pattern scaling data: $e")
    end
    
catch e
    println("✗ Pattern scaling failed: $e")
    println("\nFull error:")
    showerror(stdout, e, catch_backtrace())
end

println("\n=== Summary ===")
println("Pattern scaling test complete. Check del_ohc values above.")