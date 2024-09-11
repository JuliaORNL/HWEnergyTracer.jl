

import HWEnergyTracer


function julia_main()::Cint
    HWEnergyTracer.main(ARGS)
    return 0
end

if !isdefined(Base, :active_repl)
    julia_main()
end