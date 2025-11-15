#!/bin/bash
# filepath: /data/homezvol1/freesel/crsp/MimiGIVE.jl/scripts/test_submit.sh
#SBATCH --job-name=mimi_test
#SBATCH --output=run_%j.out
#SBATCH --error=run_%j.err
#SBATCH --time=00:30:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=2

# Use your installed Julia 1.12.1
export PATH="$HOME/julia-1.12.1/bin:$PATH"

# Change to the script directory
cd /data/homezvol1/freesel/crsp/MimiGIVE.jl/scripts

# Run the Julia script (should work directly now!)
julia test_ps.jl