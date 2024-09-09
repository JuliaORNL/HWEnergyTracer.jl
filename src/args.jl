## Functions to parse arguments in command line mode
import ArgParse

"""
Parse command line arguments and return a struct with the parsed values
returns: Inputs
"""
function parse_args(args::Vector{String})::Inputs
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
    end

    parsed_args = ArgParse.parse_args(args, parse_settings)

    # default values
    vendor = parsed_args["v"]
    device_id = parsed_args["d"]
    # sample_rate = ArgParse.get_arg(parsed_args, "sample_rate")

    # return Inputs(vendor, device_id, sample_rate)
end