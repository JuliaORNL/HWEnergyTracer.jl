
struct Inputs
    vendor::String
    device_id::UInt32
    sample_rate::Float64
    output_file::String
end

#nvml-only
struct nvmlUtilization_t
    gpu::Cuint
    memory::Cuint
end
