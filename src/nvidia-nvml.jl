
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

    file_name = inputs.output_file
    fh = open(file_name, "w")

    # write header
    write(fh, "NVIDIA NVML Power Trace\n")
    write(fh, "device_id $(inputs.device_id)\n")
    write(fh, "sample_rate $(inputs.sample_rate)\n")
    write(fh, "total_energy \n")
    write(fh,
        "Time(ms)      Power(W)     Temperature(C)   Util.gpu    Util.mem \n")

    power = Ref{Cuint}(0)
    temperature = Ref{Cuint}(0)
    utilization = nvmlUtilization_t(0, 0)
    dcount = _get_number_of_devices()
    println("Number of devices: $dcount")

    dh::Ptr{Cvoid} = _get_device_handle(inputs.device_id)

    time0_ns = time_ns()

    @inline function write_line(time0_ns)
        time_ns = time_ns() - time0_ns
        _get_device_power!(dh, power)
        _get_device_temperature!(dh, temperature)
        _get_device_utilization!(dh, utilization)

        write(fh,
            "$(time_ns)   $(power[])    $(temperature[])  $(utilization.gpu)  $(utilization.memory)\n")
    end

    while true
        try
            write_line(time0_ns)
            sleep(Float64(inputs.sample_rate / 1000))
        catch InterruptException
            # write the last line
            write_line(time0_ns)
            println("Interrupted. Closing file...")
            close(fh)
            println("Interrupted. Finalize NVML...")
            _finalize_nvml()
            break
        end
    end

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

function _get_number_of_devices()::Int32
    device_count = Ref{Cuint}(0)
    res = @ccall m_libnvidia_ml.nvmlDeviceGetCount_v2(
        device_count::Ptr{Cuint})::Int32
    if res != 0
        throw(ErrorException("Failed to get number of devices."))
    end
    return device_count[]
end

# handler functions
function _get_device_handle(device_id)::Ptr{Cvoid}
    device = Ptr{Cvoid}()
    devid = Cuint(device_id)
    res = @ccall m_libnvidia_ml.nvmlDeviceGetHandleByIndex_v2(
        devid::Cuint, device::Ptr{Cvoid})::Int32
    if res != 0
        throw(ErrorException("Failed to get device handle for device_id: $device_id, res: $res"))
    end
    return device
end

function _get_device_temperature(dh, temperature)
    @ccall m_libnvidia_ml.nvmlDeviceGetTemperature(
        dh::Ptr{Cvoid}, 0::Int32, temperature::Ptr{Cuint})::Int32
end

function _get_device_power(dh, power)
    @ccall m_libnvidia_ml.nvmlDeviceGetPowerUsage(
        dh::Ptr{Cvoid}, power::Ptr{Cuint})::Int32
end

function _get_device_utilization(dh, utilization)
    @ccall m_libnvidia_ml.nvmlDeviceGetUtilizationRates(
        dh::Ptr{Cvoid}, utilization::nvmlUtilization_t)::Int32
end
