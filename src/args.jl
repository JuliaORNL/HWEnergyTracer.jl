## Functions to parse arguments in command line mode
import ArgParse

"""
Parse command line arguments and return a struct with the parsed values
returns: Inputs
"""
function _parse_args(args::Vector{String})::Inputs
    # Parse command line arguments settings
    parse_settings = ArgParse.ArgParseSettings(;
        description = "HWEnergyTracer command line interface",
        exc_handler = ArgParse.default_handler)

    ArgParse.@add_arg_table! parse_settings begin
        "-v", "--vendor"
        help = "vendor"
        arg_type = String
        default = "NVIDIA"
        "-d", "--device_id"
        help = "device_id"
        arg_type = Int32
        default = Int32(0)
        "-r", "--sample_rate"
        help = "sample rate in ms"
        arg_type = Float64
        default = Float64(1000)
        "-o", "--output"
        help = "output file"
        arg_type = String
        default = "power-trace.csv"
        "-f", "--flush_rate"
        help = "flush rate in seconds"
        arg_type = UInt32
        default = UInt32(10)
    end

    parsed_args = ArgParse.parse_args(args, parse_settings)
    # default values
    vendor = parsed_args["vendor"]
    device_id = parsed_args["device_id"]
    sample_rate = parsed_args["sample_rate"]
    output_file = parsed_args["output"]
    flush_rate = parsed_args["flush_rate"]
    return Inputs(vendor, device_id, sample_rate, output_file, flush_rate)
end