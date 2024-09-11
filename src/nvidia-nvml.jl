
using Preferences

export set_libnvidia_ml!

function set_libnvidia_ml!(libnvidia_ml::String)
    @set_preferences!("libnvidia-ml"=>libnvidia_ml)
end

HWEnergyTracer.m_libnvidia_ml = @load_preference("libnvidia-ml",
    "/usr/lib/x86_64-linux-gnu/libnvidia-ml.so")

function _run_nvidia(inputs)

    # Will throw an exception if not found/functional
    result = _test_libnvidia_ml!()
    result = _init_nvml()
    # @TODO Implement the rest of the NVML power trace functions
    result = _write_power_trace(inputs)
    result = _finalize_nvml()

    return result
end

function _test_libnvidia_ml!()
    @static if !Sys.islinux()
        throw(ArgumentError("Only Linux is supported for NVIDIA NVML."))
    end

    libnvidia_ml = HWEnergyTracer.m_libnvidia_ml

    if !isfile(libnvidia_ml)
        throw(ArgumentError("libnvidia-ml.so file not found at: $libnvidia_ml"))
    end

    # Verify the library is Libdl compatible
    try
        p = Libdl.dlopen(libnvidia_ml, Libdl.RTLD_LAZY)
        Libdl.dlclose(p)
    catch
        throw(ArgumentError("$libnvidia_ml is not compatible with Libdl.jl and can not be loaded."))
    end

    println("Found valid NVIDIA NVML library libnvidia-ml.so at: $libnvidia_ml")
    return 0
end

function _init_nvml()::Int32
    println("Initializing NVML...")
    return @ccall m_libnvidia_ml.nvmlInit_v2()::Int32
end

function _write_power_trace(inputs::Inputs)::Int32
    @TODO "Implement the rest of the NVML power trace functions"
    return 0
end

function _finalize_nvml()::Int32
    res = @ccall m_libnvidia_ml.nvmlShutdown()::Int32
    println("Finalizing NVML...")
    return res
end