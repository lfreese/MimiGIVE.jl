import Pkg
try
    using CSV, DataFrames, Random, Statistics  
catch
    println("Installing required packages...")
    Pkg.add(["CSV", "DataFrames"])
    using CSV, DataFrames, Random, Statistics  
end

# ----------------------------------------------------------------------------
# Create fake Green's function data for testing MimiGIVE TempMortality_GreensFunction component
# Based on typical climate GF shape: immediate response with multi-timescale decay
# KEY CALIBRATION: Peak global mean should be ~2°C per 1000 GtC = 0.002°C/GtC
# ----------------------------------------------------------------------------

# Set random seed 
Random.seed!(123)

# Dimensions from your model
countries = [
    "AFG", "AGO", "ALB", "ARE", "ARG", "ARM", "AUS", "AUT", "AZE", "BDI",
    "BEL", "BEN", "BFA", "BGD", "BGR", "BHR", "BHS", "BIH", "BLR", "BLZ",
    "BOL", "BRA", "BRB", "BRN", "BTN", "BWA", "CAF", "CAN", "CHE", "CHL",
    "CHN", "CIV", "CMR", "COD", "COG", "COL", "COM", "CPV", "CRI", "CUB",
    "CYP", "CZE", "DEU", "DJI", "DMA", "DNK", "DOM", "DZA", "ECU", "EGY",
    "ERI", "ESP", "EST", "ETH", "FIN", "FJI", "FRA", "GAB", "GBR", "GEO",
    "GHA", "GIN", "GMB", "GNB", "GNQ", "GRC", "GRD", "GTM", "GUY", "HND",
    "HRV", "HTI", "HUN", "IDN", "IND", "IRL", "IRN", "IRQ", "ISL", "ISR",
    "ITA", "JAM", "JOR", "JPN", "KAZ", "KEN", "KGZ", "KHM", "KIR", "KNA",
    "KOR", "KWT", "LAO", "LBN", "LBR", "LBY", "LCA", "LKA", "LSO", "LTU",
    "LUX", "LVA", "MAR", "MDA", "MDG", "MDV", "MEX", "MHL", "MKD", "MLI",
    "MLT", "MMR", "MNE", "MNG", "MOZ", "MRT", "MUS", "MWI", "MYS", "NAM",
    "NER", "NGA", "NIC", "NLD", "NOR", "NPL", "NRU", "NZL", "OMN", "PAK",
    "PAN", "PER", "PHL", "PLW", "PNG", "POL", "PRK", "PRT", "PRY", "PSE",
    "QAT", "ROU", "RUS", "RWA", "SAU", "SDN", "SEN", "SGP", "SLB", "SLE",
    "SLV", "SMR", "SOM", "SRB", "SSD", "STP", "SUR", "SVK", "SVN", "SWE",
    "SWZ", "SYC", "SYR", "TCD", "TGO", "THA", "TJK", "TKM", "TLS", "TON",
    "TTO", "TUN", "TUR", "TUV", "TWN", "TZA", "UGA", "UKR", "URY", "USA", 
    "UZB", "VCT", "VEN", "VNM", "VUT", "WSM", "YEM", "ZAF", "ZMB", "ZWE"
]

num_countries = length(countries)
num_gcms = 1  # Just multi-model mean for testing
num_lags = 600  

println("Creating fake Green's function data...")
println("Countries: $num_countries, GCMs: $num_gcms, Lags: $num_lags")
println("Target: Peak global mean ~2°C/1000GtC = 0.002°C/GtC")
println("Shape: Multi-timescale exponential decay from immediate peak")

# Create fake Green's function local patterns
# Structure: [country × 1 × lag] for multi-model mean only
local_patterns = zeros(num_countries, 1, num_lags)
global_pattern = zeros(1, num_lags)

# CALIBRATION PARAMETERS - based on typical climate Green's functions
# Multi-timescale decay: fast (years), medium (decades), slow (centuries)
# Form: GF(t) = A1*exp(-t/τ1) + A2*exp(-t/τ2) + A3*exp(-t/τ3)

# Timescales (years)
TAU_FAST = 3.0      # Fast ocean/atmosphere adjustment
TAU_MEDIUM = 30.0   # Intermediate ocean uptake
TAU_SLOW = 300.0    # Deep ocean/long-term response

# Amplitudes (sum should give TCRE ~1.5-2°C per 1000 GtC)
# These are the initial amplitudes at lag=1
A_FAST = 0.0012     # Fast component amplitude
A_MEDIUM = 0.0006   # Medium component amplitude  
A_SLOW = 0.0002     # Slow component amplitude

for i in 1:num_countries
    # Spatial pattern: higher response at higher latitudes (Arctic amplification)
    # Range from 0.8x (tropics) to 1.4x (high latitudes)
    lat_factor = 0.8 + 0.6 * abs(sin(i / num_countries * π))
    
    # Add small country-specific variation to timescales
    tau_fast = TAU_FAST * (0.9 + 0.2 * rand())
    tau_medium = TAU_MEDIUM * (0.9 + 0.2 * rand())
    tau_slow = TAU_SLOW * (0.9 + 0.2 * rand())
    
    for k in 1:num_lags
        lag_years = Float64(k)
        
        # Multi-timescale exponential decay
        # Peak is at lag=1 (immediate response)
        value = lat_factor * (
            A_FAST * exp(-lag_years / tau_fast) +
            A_MEDIUM * exp(-lag_years / tau_medium) +
            A_SLOW * exp(-lag_years / tau_slow)
        )
        
        local_patterns[i, 1, k] = value
    end
end

# Calculate global pattern as simple average of local patterns
for k in 1:num_lags
    global_pattern[1, k] = mean(local_patterns[:, 1, k])
end

# Print diagnostics
println("\nGreen's Function Diagnostics:")
println("  Peak global value (lag=1): $(global_pattern[1, 1]) °C/GtC")
println("  Value at lag=10: $(global_pattern[1, 10]) °C/GtC")
println("  Value at lag=100: $(global_pattern[1, 100]) °C/GtC")
println("  Value at lag=500: $(global_pattern[1, 500]) °C/GtC")
println("  Integrated response (TCRE): $(sum(global_pattern)) °C/GtC")
println("  TCRE per 1000 GtC: $(sum(global_pattern) * 1000) °C/1000GtC")
println("\nTimescales:")
println("  Fast: $(TAU_FAST) years")
println("  Medium: $(TAU_MEDIUM) years")
println("  Slow: $(TAU_SLOW) years")

# Create structured CSV with global_pattern column
data_rows = []
for i in 1:num_countries
    for k in 1:num_lags
        push!(data_rows, (
            country = countries[i],
            gcm = 1,  # Only one GCM (multi-model mean)
            lag = k,
            value = local_patterns[i, 1, k],
            global_pattern = global_pattern[1, k]
        ))
    end
end

# Create DataFrame and save
df_local = DataFrame(data_rows)
output_file = "/data/homezvol1/freesel/crsp/MimiGIVE.jl/data/greens_function_local.csv"
CSV.write(output_file, df_local)

println("\nCreated: $output_file")
println("File contains $(nrow(df_local)) rows")
println("Sample data (first 10 lags for first country):")
println(first(df_local, 10))

# ---------------------------------------------------------------------------------
# Create fake pattern scaling data
# Structure: [country × 1] - just scaling factors
# ---------------------------------------------------------------------------------
println("\nCreating pattern scaling data...")

pattern_scaling_data = []
for i in 1:num_countries
    # Create realistic pattern scaling factors
    # Range from 0.5 to 2.0 (local temp = 0.5x to 2.0x global temp)
    # Higher latitudes get larger factors (Arctic amplification)
    lat_effect = abs(sin(i / num_countries * π))  # 0 at equator, 1 at poles
    scaling_factor = 0.5 + 1.5 * lat_effect  # Range: 0.5 (tropics) to 2.0 (poles)
    
    push!(pattern_scaling_data, (
        country = countries[i],
        gcm = 1,
        scaling_factor = scaling_factor
    ))
end

df_pattern = DataFrame(pattern_scaling_data)
pattern_output_file = "/data/homezvol1/freesel/crsp/MimiGIVE.jl/data/pattern_scaling_data.csv"
CSV.write(pattern_output_file, df_pattern)

println("Created: $pattern_output_file")
println("Pattern scaling file contains $(nrow(df_pattern)) rows")
println("Pattern scaling sample:")
println(first(df_pattern, 10))

println("\n✓ Test data generation complete!")
println("Expected behavior:")
println("  - Green's Functions should give realistic temps (~1-2°C by 2020)")
println("  - Shape: immediate peak with multi-timescale exponential decay")
println("  - Pattern Scaling should also give realistic temps")
println("  - Both should be comparable to FAIR method")