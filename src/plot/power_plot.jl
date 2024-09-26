
import CSV 
import Plots

function power_plot()

    # Load data
    data = CSV.read("/Users/wfg/data/qmcpack-energy/power_NiO-S8_w4096.csv", header=5)

    # Plot
    p = Plots.plot(data, x=:time, y=:power, label="Power", xlabel="Time (s)", ylabel="Power (W)", legend=:topleft)

    # Save plot
    # PNG("output/power_plot.png", 6inch, 4inch)
    # draw(PNG("output/power_plot.png", 6inch, 4inch), p)
end