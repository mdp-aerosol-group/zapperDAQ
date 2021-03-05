function getVdac(setV::Float64, polarity::Symbol, powerSwitch::Bool)
    (setV > 0.0) || (setV = 0.0)
    (setV < 10000.0) || (setV = 10000.0)

    if polarity == :-
        # Negative power supply +0.36V = -10kV, 5V = 0kV
        m = 10000.0 / (0.36 - 5)
        b = 10000.0 - m * 0.36
        setVdac = (setV - b) / m
        if setVdac < 0.36
            setVdac = 0.36
        elseif setVdac > 5.0
            setVdac = 5.0
        end
        if powerSwitch == false
            setVdac = 5.0
        end
    elseif polarity == :+
        # Positive power supply +0V = 0kV, 4.64V = 0kV
        m = 10000.0 / (4.64 - 0)
        b = 0
        setVdac = (setV - b) / m
        if setVdac < 0.0
            setVdac = 0.0
        elseif setVdac > 4.64
            setVdac = 4.64
        end
        if powerSwitch == false
            setVdac = 0.0
        end
    end
    return setVdac
end

function DAQloop(t::Float64)
    isfile(outfile) || CSV.write(outfile, df)

    setV = get_gtk_property(gui["SetVoltage"], :value, Float64)
    powerSwitch = get_gtk_property(gui["Switch"], :state, Bool)
    Vdac0 = getVdac(setV, :+, powerSwitch)
    enable = powerSwitch == true ? 3.3 : 0.0
    color = powerSwitch == true ? setLED(ADDR, "red") : setLED(ADDR, "green")
    
    setDAC(ADDR, VOUT_CHANNEL, Vdac0)
    setDAC(ADDR, ENABLE_CHANNEL, enable)

    AIN0 = @>> getADC(ADDR, VMON_CHANNEL) (x -> x * 1000.0) 
    AIN1 = @>> getADC(ADDR, IMON_CHANNEL) (x -> -x * 0.167 * 1000.0) 
   
    set_gtk_property!(gui["Voltage"], :text, @sprintf("%0.2f", AIN0))
    set_gtk_property!(gui["Current"], :text, @sprintf("%0.2f", AIN1))

    addpoint!(t, AIN0, plot1, gplot1, 1)
    addpoint!(t, AIN1, plot1, gplot1, 2)

    ts = now()

    push!(
        df,
        Dict(
            :Timestamp => ts,
            :TimeValue => Dates.value(ts),
            :voltageSet => Vdac0,
            :voltageRead => AIN0,
            :currentRead => AIN1,
            :powerSwitch => powerSwitch
        ),
    )

    df[end, :] |> DataFrame |> CSV.write(outfile; append = true)
end
