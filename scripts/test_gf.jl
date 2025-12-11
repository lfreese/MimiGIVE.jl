using Pkg
Pkg.activate("/data/homezvol1/freesel/crsp/MimiGIVE.jl")

using MimiGIVE
using Statistics
using DataFrames
using Mimi

using MimiGIVE: get_model, compute_scc, compute_scghg

using Pkg
Pkg.activate("/data/homezvol1/freesel/crsp/MimiGIVE.jl")

function test_gf_mcs()
    println("\n=== Testing Green's Function MCS ===\n")
    
    # Test 1: Single model - verify component works
    println("Test 1: Single model Green's function")
    m_single = get_model(temperature_method = :greens_function, use_multimodel = false)
    
    # Check component exists
    try
        comp = Mimi.compdef(m_single.md, :TempMortality_GreensFunction)
        println("  ✓ TempMortality_GreensFunction component exists")
    catch e
        error("TempMortality_GreensFunction component missing from model")
    end
    
    # Run single model
    println("  Running single model...")
    run(m_single)
    global_temp_single = m_single[:TempMortality_GreensFunction, :global_temperature]
    println("  ✓ Model ran successfully")
    println("  Temperature range: $(round(global_temp_single[1], digits=3))°C to $(round(global_temp_single[end], digits=2))°C")
    
    # Test 2: Multimodel - check dimensions
    println("\nTest 2: Multimodel setup")
    m_multi = get_model(temperature_method = :greens_function, use_multimodel = true)
    
    try
        comp = Mimi.compdef(m_multi.md, :TempMortality_GreensFunction)
        println("  ✓ TempMortality_GreensFunction component exists in multimodel")
    catch e
        error("TempMortality_GreensFunction component missing from multimodel")
    end
    
    # Run multimodel
    println("  Running multimodel...")
    run(m_multi)
    global_temp_multi = m_multi[:TempMortality_GreensFunction, :global_temperature]
    println("  ✓ Multimodel ran successfully")
    println("  Global temp array size: $(size(global_temp_multi))")
    
    # Check array dimensions
    if ndims(global_temp_multi) >= 2
        println("  Array has $(ndims(global_temp_multi)) dimensions")
        
        # Try to extract data for different GCMs if available
        if size(global_temp_multi, ndims(global_temp_multi)) > 1
            n_gcms = size(global_temp_multi, ndims(global_temp_multi))
            println("  Number of GCMs in array: $n_gcms")
            
            # Show final temps for first few GCMs
            println("  Final year temperatures by GCM:")
            for i in 1:min(5, n_gcms)
                if ndims(global_temp_multi) == 2
                    temp = global_temp_multi[end, i]
                elseif ndims(global_temp_multi) == 3
                    temp = mean(global_temp_multi[end, :, i])
                else
                    temp = global_temp_multi[end]
                end
                println("    GCM $i: $(round(temp, digits=2))°C")
            end
        end
    end
    
    println("\n=== All tests completed successfully! ===\n")
end

# Run the tests
test_gf_mcs()