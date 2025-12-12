@defcomp TempMortality_GreensFunction begin
    country = Index()
    cmip6_gcms = Index()
    lag = Index()

    gcm_id             = Parameter{Int64}(default = 1)  # Can be single value or sampled in MCS
    pattern            = Parameter(index=[country, cmip6_gcms, lag])
    forcing            = Parameter(index=[time])
    dt                 = Parameter{Float64}(default = 1.0)
    global_pattern     = Parameter(index=[cmip6_gcms, lag])

    local_temperature  = Variable(index=[time, country], unit = "degC")
    global_temperature = Variable(index=[time], unit = "degC")
    
    function run_timestep(p, v, d, t)
        current_idx = findfirst(ts -> ts == t, d.time)
        
        # global temperature
        forcing_val = p.forcing[t]
        forcing_gtc = (ismissing(forcing_val) ? 0.0 : Float64(forcing_val))
        
        if current_idx == 1
            v.global_temperature[t] = p.global_pattern[p.gcm_id, 1] * forcing_gtc * p.dt
        else
            current_contribution = p.global_pattern[p.gcm_id, 1] * forcing_gtc * p.dt
            
            past_contribution = 0.0
            for past_idx in 1:(current_idx-1)
                lag = current_idx - past_idx
                if lag <= length(d.lag)
                    past_forcing = p.forcing[TimestepIndex(past_idx)]
                    past_gtc = (ismissing(past_forcing) ? 0.0 : Float64(past_forcing))
                    past_contribution += p.global_pattern[p.gcm_id, lag] * past_gtc * p.dt
                end
            end
            
            v.global_temperature[t] = current_contribution + past_contribution
        end
        
        # Local temperatures
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
                        past_gtc = (ismissing(past_forcing) ? 0.0 : Float64(past_forcing))
                        past_contribution += p.pattern[c, p.gcm_id, lag] * past_gtc * p.dt
                    end
                end
                
                v.local_temperature[t, c] = current_contribution + past_contribution
            end
        end
    end
end