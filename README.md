# HWEnergyTracer.jl
Provide energy information, e.g. simple power traces, wrapping vendor tools. GPUs: NVML, rocm-smi-lib


## Configuration

1. Requires Julia v1.9 or above from their official [website](https://julialang.org/downloads/).

2. Clone this repository and install the required packages.

    ```bash
    git clone https://github.com/JuliaORNL/HWEnergyTracer.jl.git
    cd HWEnergyTracer.jl
    julia --project=. -e 'using Pkg; Pkg.instantiate()'
    ```

2. For NVIDIA: 
   1. Requires a NVIDIA driver and CUDA capabilities
   2. CUDA.jl package must be setup to detect the CUDA installation. See [docs](https://cuda.juliagpu.org/stable/installation/overview/#Using-a-local-CUDA)

    Example: 

    Point at the local CUDA installation, *replace below with the appropriate CUDA version*:
    
    ```
    $ julia --project -e 'using CUDA; CUDA.set_runtime_version!(v"12.6"; local_toolkit=true)'
    ```
    
    Verify the installation
    
    ```
    $ julia --project -e 'using CUDA; CUDA.versioninfo()'
    CUDA runtime 12.6, local installation
    CUDA driver 12.5
    NVIDIA driver 555.42.6
    ...
    2 devices:
    0: NVIDIA H100 NVL (sm_90, 93.119 GiB / 93.584 GiB available)
    1: NVIDIA H100 NVL (sm_90, 93.119 GiB / 93.584 GiB available)
    ```

3. For AMD GPUs:
   
   1. Requires ROCm installation and rocm-smi-lib
   2. Set up `rocm-smi-lib` location. Default is `/opt/rocm/lib/librocm_smi64.so`.

    Example:
    
    ```
    $ julia --project -e 'using HWEnergyTracer; HWEnergyTracer.set_rocm_lib_path("/opt/rocm-6.2.0/lib/librocm_smi64.so")'
    ```

    will create a LocalPreferences.toml file in the project directory with the path to the `rocm-smi-lib` library.

    ```
    $ cat LocalPreferences.toml
      
      [HWEnergyTracer]
      librocm_smi = "/opt/rocm-6.2.0/lib/librocm_smi64.so"
    ```

## Running the tracer

    Typically the tracer would run in parallel to an application. Allow ~10-15s to launch before (due to JIT) and kill after (for static power), as in the following script:

    ```
    HWTracer_DIR=/path/to/HWEnergyTracer.jl
    echo "Starting HWEnergyTracer.jl"
    julia -t 1 --project=$HWTracer_DIR $HWTracer_DIR/hw-energy-tracer.jl -v AMD -r 1 -o power_1ms.csv &

    tracer_pid=$!
    sleep 15
    echo "Starting Process"
    ./my_process arg1 arg2 arg3
    my_process_pid=$!

    wait "$my_process_pid"
    echo "End Process"
    sleep 15
    kill -2 "$tracer_pid"
    echo "End HWEnergyTracer.jl"
    ```
    
    The tracer will generate a CSV file with power information. The CSV file will have the following columns for NVIDIA and AMD GPUs (this will be updated as needed):

    ```
    NVIDIA NVML Power Trace
    device_id 0
    sample_rate 100.0
    total_energy 
    Time(s) Power(W) Temperature(C) Util.gpu(%) Util.mem(%) Clock.sm(MHz) Clock.memory(MHz)
    0.000000 44 32 0 0 210 1512
    0.380302 44 32 0 0 210 1512
    ```

    ```
    ROCM SMI Power Trace
    device_id 0
    sample_rate 1000.0
    total_energy 
    Time(s)                Power(W)  Temperature(C) Util.gpu(%) Util.mem(%) 
    0.000000 87 35 0 0
    0.244688 88 37 0 0
    1.246900 88 35 0 0
    2.249522 88 36 0 0
    3.252087 87 36 0 0
    ```

    Examples for doing analysis on the power traces can be found in the `src/plot` directory.

    Argument options for the tracer are:

    - `-d` device id, relevant to multi-GPU nodes. Default is 0 and will only trace one GPU at a time. Launch a separate tracer process for each GPU.
    - `-o` output file name for the csv file. Default is `power.csv`
    - `-r` sampling rate in milliseconds. Default is 1ms
    - `-v` vendor. Default is `NVIDIA`. Other option is `AMD` for AMD GPUs.
    - `-f` flush rate in seconds. Default is 10s. The tracer will flush the data to the file every `f` seconds.

## Acknowledgements

This work is funded by an EXPRESS project in the US Department of Energy's Advanced Scientific Computing Office (ASCR).
