module HWEnergyTracer

import Libdl

# location of the AMD librocm_smi shared library from Preferences. 
# No need for libnvidia-ml as it's handled by the CUDA.jl package
m_librocm_smi = nothing

include("structs.jl")
include("args.jl")

include("cuda-nvml.jl")
include("librocm_smi.jl")

function main(args::Vector{String})
    inputs::Inputs = _parse_args(args)
    vendor_lc = lowercase(inputs.vendor)

    if vendor_lc == "nvidia"
        _run_nvidia(inputs)
    elseif vendor_lc == "amd"
        _run_amd(inputs)
    else
        throw(ArgumentError("Invalid vendor: \"$(inputs.vendor)\""))
    end
end # function main

end # module HWEnergyTracer
