using Mimi

# ------------------------------------------------------------------------------
# Calculate population-weighted, country-level temperatures using a Green's function
# pattern that is convolved with the global_temperature time series.
# The `pattern` parameter is now indexed by lag (1 = current timestep, 2 = previous, ...)
# and the component performs a causal convolution:
#   local[t,c] = sum_{L=1..Lmax and (t-L+1)>=1} pattern[c, gcm_id, L] * forcing[t-L+1]
# Also calculates global mean temperature for use by other damage modules.
# ------------------------------------------------------------------------------

@defcomp TempMortality_GreensFunction begin

    country = Index()
    cmip6_gcms = Index()
    lag = Index() # convolution kernel lag (1 = current timestep, 2 = previous timestep, ...)

    gcm_id             = Parameter{Int64}(default = 5) # the pattern gcm id to use, default to ** ##TODO determine default
    # Green's function kernel: indexed by country, gcm and lag.
    # pattern[c, gcm, 1] is the response at the same timestep to an impulse at that timestep,
    # pattern[...,2] is the response one timestep later to an impulse at the previous timestep, etc.
    # Units: e.g. degC per (unit of forcing). For emissions forcing in GtC/yr, use degC per GtC and set dt accordingly.
    pattern            = Parameter(index=[country, cmip6_gcms, lag])
    # Forcing time series to convolve with the Green's Function (e.g., CO2 emissions, same time index as `time`).
    forcing            = Parameter(index=[time])
    # Timestep width to multiply the discrete sum by (default 1.0 for yearly data). Set appropriately if your
    # time axis has a different spacing.
    dt                 = Parameter(default = 1.0)
    
    # Global mean Green's function kernel for calculating global temperature
    # Units: degC per (unit of forcing), same as local pattern
    global_pattern     = Parameter(index=[cmip6_gcms, lag])

    local_temperature = Variable(index=[time,country], unit = "degC") # Country-level temperatures derived from the convolution.
    global_temperature = Variable(index=[time], unit = "degC") # Global mean temperature derived from the convolution.

    function run_timestep(p, v, d, t)
        # Calculate local temperatures for each country
        for c in d.country
            acc = 0.0
            for L in d.lag
                # Map lag L (1-based) to a source time index s: lag=1 -> s = t (current timestep);
                # lag=2 -> s = t-1 (previous), etc.
                s = t - (L - 1)
                # Skip kernel terms that reference times before the start of the series
                # or that are not present in the model's time index (works with non-integer time indices).
                if !(s in d.time)
                    continue
                end
                # Discrete convolution: sum G(lag) * forcing[s] * dt
                acc += p.pattern[c, p.gcm_id, L] * p.forcing[s] * p.dt
            end
            v.local_temperature[t,c] = acc
        end
        
        # Calculate global mean temperature
        global_acc = 0.0
        for L in d.lag
            s = t - (L - 1)
            if !(s in d.time)
                continue
            end
            global_acc += p.global_pattern[p.gcm_id, L] * p.forcing[s] * p.dt
        end
        v.global_temperature[t] = global_acc
    end
end