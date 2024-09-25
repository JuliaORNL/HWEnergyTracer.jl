
using Preferences

export set_librocm_smi!

HWEnergyTracer.m_librocm_smi = @load_preference("librocm_smi",
	"/opt/rocm/lib/librocm_smi64.so")

function set_librocm_smi!(librocm_smi::String)
	@set_preferences!("librocm_smi" => librocm_smi)
end

function _run_amd(inputs)

	# Will throw an exception if not found/functional
	result = _test_librocm_smi!()
	result = _init_rocm_smi()
	result = _write_power_trace_amd(inputs)

	return result
end

function _test_librocm_smi!()
	@static if !Sys.islinux()
		throw(ArgumentError("Only Linux is supported for AMD ROCm SMI."))
	end

	librocm_smi = HWEnergyTracer.m_librocm_smi

	if !isfile(librocm_smi)
		throw(ArgumentError("librocm_smi.so or librocm_smi64.so file not found at: $librocm_smi"))
	end

	# Verify the library is Libdl compatible
	try
		p = Libdl.dlopen(librocm_smi, Libdl.RTLD_LAZY)
		Libdl.dlclose(p)
	catch
		throw(ArgumentError("$librocm_smi is not compatible with Libdl.jl and can not be loaded."))
	end

	println("Found valid AMD ROCm SMI library librocm_smi at: $librocm_smi")
end

function _init_rocm_smi()::Int32
	println("Initializing ROCm SMI...")
	return @ccall m_librocm_smi.rsmi_init(0::Culonglong)::Int32
end

function _write_power_trace_amd(inputs)

	fh = open(inputs.output_file, "w")
	_write_header_amd(fh, inputs)
	flush(fh) # write the header to the file

	time0_ns = time_ns()
	dev_id = inputs.device_id
	_write_line_amd(dev_id, fh, time0_ns, time0_ns, inputs.flush_rate)

	while true
		try
			current_time = time_ns()
			_write_line_amd(dev_id, fh, current_time, time0_ns, inputs.flush_rate)
			sleep(Float64(inputs.sample_rate / 1000.0))

		catch InterruptException
			# write the last line
			_write_line_amd(dev_id, fh, time_ns(), time0_ns, inputs.flush_rate)
			println("Interrupted. Closing file...")
			close(fh)
			println("Interrupted. Finalize ROCM SMI...")
			_finalize_rocm_smi()
			break
		end
	end

	return 0
end

function _write_header_amd(fh, inputs)
	write(fh, "ROCM SMI Power Trace\n")
	write(fh, "device_id $(inputs.device_id)\n")
	write(fh, "sample_rate $(inputs.sample_rate)\n")
	write(fh, "total_energy \n")
	write(fh,
		"Time(s)                Power(W)  Temperature(C) Util.gpu(%) Util.mem(%) \n")
end

function _write_line_amd(dev_id, fh, current_time, time0_ns, flush_rate)
	elapsed = (current_time - time0_ns) / 1E9
	power = _get_device_power(dev_id)
	temperature = _get_device_temperature(dev_id)
	utilization_compute = _get_device_utilization_compute(dev_id)
	utilization_memory = _get_device_utilization_memory(dev_id)

	Printf.@printf(fh,
		"%.6f   %.2f   %.2f   %d  %.2f\n", Float64(elapsed),
		power, temperature, utilization_compute, utilization_memory)

	if floor(elapsed) % flush_rate == 0
		flush(fh)
	end
end

function _get_device_power(dev_id)::Float32
	power = Ref{Clonglong}()
	result = @ccall m_librocm_smi.rsmi_dev_power_ave_get(
		dev_id::Cuint, 0::Cuint, power::Ptr{Clonglong})::Int32
	# power is given in microWatts, converting to Watts
	return Float32(power[] / 1E6)
end

function _get_device_temperature(dev_id)::Float32
	temperature = Ref{Clonglong}()
	result = @ccall m_librocm_smi.rsmi_dev_temp_metric_get(
		dev_id::Cuint, 1::Cuint, 0::Cint, temperature::Ptr{Clonglong})::Int32
	return Float32(temperature[] / 1000)
end

function _get_device_utilization_compute(dev_id)::Int32
	utilization = Ref{Cint}()
	result = @ccall m_librocm_smi.rsmi_dev_busy_percent_get(
		dev_id::Cuint, utilization::Ptr{Cint})::Int32
	return Int32(utilization[])
end

function _get_device_utilization_memory(dev_id)::Float32
	used = Ref{Clonglong}()
	result = @ccall m_librocm_smi.rsmi_dev_memory_usage_get(
		dev_id::Cuint, 0::Cint, used::Ptr{Clonglong})::Int32
	total = Ref{Clonglong}()
	result = @ccall m_librocm_smi.rsmi_dev_memory_total_get(
		dev_id::Cuint, 0::Cint, total::Ptr{Clonglong})::Int32
	return Float32(used[] / total[])
end

function _finalize_rocm_smi()::Int32
	return @ccall m_librocm_smi.rsmi_shut_down()::Int32
end
