
module HWEnergyTracerPreferences

export set_system_vendor
using Preferences
using Libdl

"""
Sets the system library for a particular vendor if standard installation is available.
    Argument
    - vendor: NVIDIA (NVML libnvidia-ml), AMD (rocm-smi-lib)
"""
function set_system_vendor(vendor::String)
    vendor_lc = lowercase(vendor)
    if !(vendor_lc in ("nvidia", "amd"))
        throw(ArgumentError("Invalid vendor: \"$(vendor)\""))
    end

    if vendor_lc == "nvidia"
        _set_system_nvidia_nvml()
    elseif vendor_lc == "amd"
        _set_system_rocm_smi_lib()
    end
end

function _set_system_nvidia_nvml()
    libnvidia_ml = _find_libnvidia_ml()
    if !isfile(libnvidia_ml)
        throw(ArgumentError("libnvidia-ml.so not found at: $libnvidia_ml"))
    end

    # Verify the library is Libdl compatible
    try
        p = dlopen(libnvidia_ml, RTLD_LAZY)
        dlclose(p)
    catch
        throw(ArgumentError("$libnvidia_ml is not compatible with Libdl.jl and can not be loaded."))
    end

    println("Found valid NVIDIA NVML library libnvidia-ml.so at: $libnvidia_ml")
    println("Setting [HWEnergyTracer] libnvidia-ml entry in LocalPreferences.toml")
    Preferences.set_preferences!(
        "HWEnergyTracer", "libnvidia-ml" => "$libnvidia_ml"; force = true)
end

function _find_libnvidia_ml()
    println("Finding NVIDIA NVML library libnvidia-ml.so from \$CUDA_HOME environment variable.")
    cuda_home = ENV["CUDA_HOME"]
    println("\$CUDA_HOME: $cuda_home")

    if isempty(cuda_home)
        throw(ArgumentError("\$CUDA_HOME environment variable not found. 
                             Check for a valid CUDA installation."))
    end

    @static if !Sys.islinux()
        throw(ArgumentError("Only Linux is supported for NVIDIA NVML."))
    end

    arch = Sys.ARCH == :powerpc64le ? :ppc64le :
           Sys.ARCH == :aarch64 ? :sbsa :
           Sys.ARCH

    libnvidia_ml = joinpath(
        cuda_home, "targets", "$arch-linux", "lib", "stubs", "libnvidia-ml.so")
    return libnvidia_ml
end

function _set_system_rocm_smi_lib()
end

end # module HWEnergyTracerPreferences
