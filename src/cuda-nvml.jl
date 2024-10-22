
import CUDA.NVML
import Printf

function _run_nvidia(inputs)

    # Will throw an exception if not found/functional
    if !NVML.has_nvml()
        throw(ArgumentError("NVIDIA NVML couldn't not be found."))
    end

    NVML.nvmlInit_v2()
    _write_power_trace(inputs)
end

function _write_power_trace(inputs)
    dh = NVML.Device(inputs.device_id)
    fh = open(inputs.output_file, "w")
    _write_header(fh, inputs)
    flush(fh) # write the header to the file

    time0_ns = time_ns()
    _write_line(dh, fh, time0_ns, time0_ns, inputs.flush_rate)

    while true
        try
            current_time = time_ns()
            _write_line(dh, fh, current_time, time0_ns, inputs.flush_rate)
            sleep(Float64(inputs.sample_rate / 1000.0))

        catch InterruptException
            # write the last line
            _write_line(dh, fh, time_ns(), time0_ns, inputs.flush_rate)
            println("Interrupted. Closing file...")
            close(fh)
            println("Interrupted. Finalize NVML...")
            NVML.nvmlShutdown()
            break
        end
    end

    return 0
end

function _write_header(fh, inputs)
    write(fh, "NVIDIA NVML Power Trace\n")
    write(fh, "device_id $(inputs.device_id)\n")
    write(fh, "sample_rate $(inputs.sample_rate)\n")
    write(fh, "total_energy \n")
    write(fh, "Time(s) Power(W) Temperature(C) Util.gpu(%) Util.mem(%) Clock.sm(MHz) Clock.graphics(MHz) Clock.memory(MHz) Clock.video(MHz)\n")
end

function _write_line(dh, fh, current_time, time0_ns, flush_rate)
    elapsed = (current_time - time0_ns) / 1E9
    power = NVML.power_usage(dh)
    temperature = NVML.temperature(dh)
    utilization = NVML.utilization_rates(dh)
    clock_sm = NVML.clock_info(dh)[:sm]
    clock_graphics = NVML.clock_info(dh)[:graphics]
    clock_memory = NVML.clock_info(dh)[:memory]
    clock_video = NVML.clock_info(dh)[:video]

    Printf.@printf(fh,
        "%.6f %d %d %d %d %d %d %d %d\n", Float64(elapsed),
        power, temperature, utilization.compute*100, utilization.memory*100, 
        clock_sm, clock_graphics, clock_memory, clock_video)

    if floor(elapsed) % flush_rate == 0
        flush(fh)
    end
end