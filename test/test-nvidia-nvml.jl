
using Test
import HWEnergyTracer

@testset "Test NVIDIA NVML" begin
    @test HWEnergyTracer._test_libnvidia_ml!() == 0
    @test HWEnergyTracer._init_nvml() == 0
    @test HWEnergyTracer._finalize_nvml() == 0

    ##@test HWEnergyTracer._run_nvidia(["--vendor", "NVIDIA"])
end
