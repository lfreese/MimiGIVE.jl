#!/bin/bash
# filepath: /data/homezvol1/freesel/crsp/MimiGIVE.jl/scripts/test_submit.sh
#SBATCH --job-name=mimi_test
#SBATCH --output=run_%j.out
#SBATCH --error=run_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=4

# Use your installed Julia 1.12.1
export PATH="$HOME/julia-1.12.1/bin:$PATH"

# Change to the script directory
cd /data/homezvol1/freesel/crsp/MimiGIVE.jl/scripts

#make our GF data
julia prep_GF_tester.jl

# Run the Julia script 
julia test_all.jl