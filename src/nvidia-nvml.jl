
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
    # Implement the rest of the NVML power trace functions
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
    # @TODO "Implement the rest of the NVML power trace functions"

    file_name = inputs.file
    fh = open(file_name, "w")

    # write header
    write(fh, "NVIDIA NVML Power Trace\n")
    write(fh, "device_id $(inputs.device_id)\n")
    write(fh, "sample_rate $(inputs.sample_rate)\n")
    write(fh, "total_energy \n")
    write(fh, "Time(ms)      Power(W)      Temperature(C)       \n")

    power = Int32(0)
    temperature = Int32(0)

    dh::Ptr{Cvoid} = _get_device_handle(inputs.device_id)

    while true
        try

        catch InterruptException
            # write the last line
            println("Interrupted. Closing file...")
            break
        end
    end

    close(fh)
    return 0
end

function _finalize_nvml()::Int32
    res = @ccall m_libnvidia_ml.nvmlShutdown()::Int32
    println("Finalizing NVML...")
    if res != 0
        throw(ErrorException("Failed to finalize NVML."))
    end

    return res
end

# handler functions

function _get_device_handle(device_id::UInt32)::Ptr{Cvoid}
    device = Ptr{Cvoid}()
    res = @ccall m_libnvidia_ml.nvmlDeviceGetHandleByIndex_v2(
        device_id, device)::Int32
    if res != 0
        throw(ErrorException("Failed to get device handle for device_id: $device_id"))
    end
    return device
end