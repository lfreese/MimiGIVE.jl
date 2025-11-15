using Mimi

# ------------------------------------------------------------------------------
# Calculate population-weighted, country-level temperatures using a Green's function
# pattern that is convolved with the global_temperature time series.
# The `pattern` parameter is now indexed by lag (1 = current timestep, 2 = previous, ...)
# and the component performs a causal convolution:
#   local[t,c] = sum_{L=1..Lmax and (t-L+1)>=1} pattern[c, gcm_id, L] * forcing[t-L+1]
# Also calculates global mean temperature for use by other damage modules.
# ------------------------------------------------------------------------------

using Mimi

using Mimi

@defcomp TempMortality_GreensFunction begin

    country = Index()
    cmip6_gcms = Index()
    lag = Index()

    gcm_id             = Parameter{Int64}(default = 5)
    pattern            = Parameter(index=[country, cmip6_gcms, lag])
    forcing            = Parameter(index=[time])
    dt                 = Parameter{Float64}(default = 1.0)
    global_pattern     = Parameter(index=[cmip6_gcms, lag])

    local_temperature  = Variable(index=[time, country], unit = "degC")
    global_temperature = Variable(index=[time], unit = "degC")
    
    function init(p, v, d)
        # Initialize all temperature values to 0.0 to avoid missing values
        println("=== TempMortality_GreensFunction INIT ===")
        println("  Number of timesteps: $(length(d.time))")
        println("  Number of countries: $(length(d.country))")
        println("  Number of lags: $(length(d.lag))")
        println("  GCM ID: $(p.gcm_id)")
        println("  dt: $(p.dt)")
        
        # Check pattern dimensions and sample values
        println("  Pattern array size: $(size(p.pattern))")
        println("  Global pattern array size: $(size(p.global_pattern))")
        println("  Sample pattern values [country 1, gcm $(p.gcm_id), lags 1-5]: $(p.pattern[1, p.gcm_id, 1:min(5, length(d.lag))])")
        println("  Sample global pattern values [gcm $(p.gcm_id), lags 1-5]: $(p.global_pattern[p.gcm_id, 1:min(5, length(d.lag))])")
        
        for t in d.time
            v.global_temperature[t] = 0.0
            for c in d.country
                v.local_temperature[t, c] = 0.0
            end
        end
        println("=== INIT COMPLETE ===\n")
    end
    
    function run_timestep(p, v, d, t)
        current_idx = findfirst(ts -> ts == t, d.time)
        year = gettime(t)
        
        # Convert CO2 emissions from Gt CO2 to GtC (molecular weight ratio: C=12, CO2=44)
        CO2_TO_C = 12.0 / 44.0
        
        # Calculate global mean temperature first
        global_temp = 0.0
        
        for L in d.lag
            source_idx = current_idx - (L - 1)
            
            if source_idx >= 1
                forcing_val = p.forcing[TimestepIndex(source_idx)]
                forcing_clean = ismissing(forcing_val) ? 0.0 : Float64(forcing_val)
                forcing_clean *= CO2_TO_C  # Convert to GtC
                contribution = p.global_pattern[p.gcm_id, L] * forcing_clean * p.dt
                global_temp += contribution
            end
        end
        
        v.global_temperature[t] = global_temp
        
        # Debug output for first few timesteps and any extreme values
        if current_idx <= 10 || abs(global_temp) > 200.0
            println("Year $year (idx=$current_idx): global_temp = $global_temp °C")
            if abs(global_temp) > 200.0
                println("  WARNING: Extreme temperature detected!")
                println("  Examining contributions:")
                for L in 1:min(10, length(d.lag))
                    source_idx = current_idx - (L - 1)
                    if source_idx >= 1
                        forcing_val = p.forcing[TimestepIndex(source_idx)]
                        forcing_clean = ismissing(forcing_val) ? 0.0 : Float64(forcing_val)
                        forcing_clean *= CO2_TO_C  # Convert to GtC
                        contribution = p.global_pattern[p.gcm_id, L] * forcing_clean * p.dt
                        println("    Lag $L: forcing=$forcing_clean, pattern=$(p.global_pattern[p.gcm_id, L]), contrib=$contribution")
                    end
                end
            end
        end
        
        # Calculate local temperatures for each country
        for c in d.country
            local_temp = 0.0
            
            for L in d.lag
                source_idx = current_idx - (L - 1)
                
                if source_idx >= 1
                    forcing_val = p.forcing[TimestepIndex(source_idx)]
                    forcing_clean = ismissing(forcing_val) ? 0.0 : Float64(forcing_val)
                    forcing_clean *= CO2_TO_C  # Convert to GtC
                    local_temp += p.pattern[c, p.gcm_id, L] * forcing_clean * p.dt
                end
            end
            
            v.local_temperature[t, c] = local_temp
        end
    end
end