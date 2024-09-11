module HWEnergyTracer

import Libdl

# location of the NVML shared library
m_libnvidia_ml = nothing

include("structs.jl")
include("args.jl")

include("nvidia-nvml.jl")

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
