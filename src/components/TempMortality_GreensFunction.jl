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
        println("=== TempMortality_GreensFunction INIT ===")
        println("  Number of timesteps: $(length(d.time))")
        println("  Number of countries: $(length(d.country))")
        println("  Number of lags: $(length(d.lag))")
        println("  GCM ID: $(p.gcm_id)")
        println("  Sum of global_pattern: $(sum(p.global_pattern[p.gcm_id, :]))")
        
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
        
        # Convert CO2 emissions from Gt CO2 to GtC
        CO2_TO_C = 12.0 / 44.0
        
        # Calculate CUMULATIVE global temperature
        # Sum ALL contributions from ALL past emissions at ALL their lags up to current time
        global_temp = 0.0
        
        for emission_idx in 1:current_idx
            for lag_idx in 1:length(d.lag)
                # This emission's lag_idx effect occurs at timestep: emission_idx + lag_idx - 1
                timestep_of_effect = emission_idx + lag_idx - 1
                
                # Include ALL effects that happened at or before current_idx
                if timestep_of_effect <= current_idx
                    forcing_val = p.forcing[TimestepIndex(emission_idx)]
                    forcing_gtc = (ismissing(forcing_val) ? 0.0 : Float64(forcing_val)) * CO2_TO_C
                    
                    global_temp += p.global_pattern[p.gcm_id, lag_idx] * forcing_gtc * p.dt
                end
            end
        end
        
        v.global_temperature[t] = global_temp
        
        # Calculate CUMULATIVE local temperatures
        for c in d.country
            local_temp = 0.0
            
            for emission_idx in 1:current_idx
                for lag_idx in 1:length(d.lag)
                    timestep_of_effect = emission_idx + lag_idx - 1
                    
                    if timestep_of_effect <= current_idx
                        forcing_val = p.forcing[TimestepIndex(emission_idx)]
                        forcing_gtc = (ismissing(forcing_val) ? 0.0 : Float64(forcing_val)) * CO2_TO_C
                        
                        local_temp += p.pattern[c, p.gcm_id, lag_idx] * forcing_gtc * p.dt
                    end
                end
            end
            
            v.local_temperature[t, c] = local_temp
        end
    end
end