
struct Inputs
    vendor::String
    device_id::UInt32
    sample_rate::Float64 # miliseconds
    output_file::String
    flush_rate::UInt32 # seconds
end
