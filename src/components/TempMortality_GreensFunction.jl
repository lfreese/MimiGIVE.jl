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
        println("  First 10 pattern values: $(p.global_pattern[p.gcm_id, 1:10])")
        println("  Last 10 pattern values: $(p.global_pattern[p.gcm_id, end-9:end])")
        
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
        #CO2_TO_C = 12.0 / 44.0
        
        # Calculate temperature contribution from THIS TIMESTEP ONLY
        # The Green's function already accounts for all historical effects
        forcing_val = p.forcing[t]
        forcing_gtc = (ismissing(forcing_val) ? 0.0 : Float64(forcing_val))# * CO2_TO_C
        
        # Temperature is just current forcing times pattern at lag=1, plus accumulation from past
        if current_idx == 1
            # First timestep
            v.global_temperature[t] = p.global_pattern[p.gcm_id, 1] * forcing_gtc * p.dt
            
            # Diagnostic for first timestep
            year = gettime(t)
            println("  Year $year: New = $(round(v.global_temperature[t], digits=6))°C, " *
                   "Cumulative = $(round(v.global_temperature[t], digits=6))°C, " *
                   "Forcing = $(round(forcing_gtc, digits=4)) GtC")
        else
            # Add contribution from current emissions at lag 1
            current_contribution = p.global_pattern[p.gcm_id, 1] * forcing_gtc * p.dt
            
            # Add lagged contributions from past emissions
            past_contribution = 0.0
            for past_idx in 1:(current_idx-1)
                lag = current_idx - past_idx
                if lag <= length(d.lag)
                    past_forcing = p.forcing[TimestepIndex(past_idx)]
                    past_gtc = (ismissing(past_forcing) ? 0.0 : Float64(past_forcing))# * CO2_TO_C
                    past_contribution += p.global_pattern[p.gcm_id, lag] * past_gtc * p.dt
                end
            end
            
            v.global_temperature[t] = current_contribution + past_contribution
            
            # Enhanced diagnostics for first 10 timesteps
            year = gettime(t)
            if current_idx <= 10
                println("  Year $year: New = $(round(current_contribution, digits=6))°C, " *
                       "Past = $(round(past_contribution, digits=6))°C, " *
                       "Cumulative = $(round(v.global_temperature[t], digits=6))°C, " *
                       "Forcing = $(round(forcing_gtc, digits=4)) GtC")
            elseif current_idx % 50 == 0
                println("  Year $year: T = $(round(v.global_temperature[t], digits=3))°C, " *
                       "Forcing = $(round(forcing_gtc, digits=2)) GtC")
            end
        end
        
        # Calculate local temperatures the same way
        for c in d.country
            if current_idx == 1
                v.local_temperature[t, c] = p.pattern[c, p.gcm_id, 1] * forcing_gtc * p.dt
            else
                current_contribution = p.pattern[c, p.gcm_id, 1] * forcing_gtc * p.dt
                
                past_contribution = 0.0
                for past_idx in 1:(current_idx-1)
                    lag = current_idx - past_idx
                    if lag <= length(d.lag)
                        past_forcing = p.forcing[TimestepIndex(past_idx)]
                        past_gtc = (ismissing(past_forcing) ? 0.0 : Float64(past_forcing))# * CO2_TO_C
                        past_contribution += p.pattern[c, p.gcm_id, lag] * past_gtc * p.dt
                    end
                end
                
                v.local_temperature[t, c] = current_contribution + past_contribution
            end
        end
    end
end