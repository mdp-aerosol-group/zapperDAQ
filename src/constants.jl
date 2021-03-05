function getcurrentfile()
    a = pwd() |> x -> split(x, "/")
    path = mapreduce(a -> "/" * a, *, a[2:3]) * "/Data/"
    path * Dates.format(now(), "yyyymmdd") * ".csv"
end

const _Gtk = Gtk.ShortNames
const black = RGBA(0, 0, 0, 1)
const red = RGBA(0.8, 0.2, 0, 1)
const lpm = 1.666666e-5

const ADDR = 0
const VOUT_CHANNEL = 0
const ENABLE_CHANNEL = 1
const VMON_CHANNEL = 0
const IMON_CHANNEL = 1

const outfile = getcurrentfile()
const switch = Reactive.Signal(false)
const bufferlength = 400
const df = DataFrame(
    Timestamp = DateTime[],
    TimeValue = Int[],
    voltageSet = Float64[],
    voltageRead = Float64[],
    currentRead = Float64[],
    powerSwitch = Bool[]
)

const gui = GtkBuilder(filename = pwd() * "/gui.glade")
const wnd = gui["mainWindow"]

const plot1 = graph1()
const mp1, gplot1 = push_plot_to_gui!(plot1, gui["housekeeping1"], wnd)
const wfrm1 = add(plot1, [0.0], [0.0], id = "V (V)")
wfrm1.line = line(color = black, width = 2, style = :solid)
const wfrm2 = add(plot1, [0.0], [0.0], id = "I (μA)")
wfrm2.line = line(color = red, width = 2, style = :solid)
