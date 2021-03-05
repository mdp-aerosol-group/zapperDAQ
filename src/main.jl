using Gtk
using InspectDR
using Reactive
using Colors
using Printf
using Dates
using CSV
using DataFrames
using NumericIO
using DAQC2Plate
using Lazy

include("initialize_graphs.jl")
include("constants.jl")
include("daq_functions.jl")

const reftime = time()
const ticks = every(1.0)
const timestamps = map(_ -> time() - reftime, ticks) 
const DAQ = map(DAQloop, timestamps)               

Gtk.set_gtk_property!(wnd, :title, "Zapper DAQ")
Gtk.set_gtk_property!(gui["DataFile"], :text, outfile)

Gtk.showall(wnd);

:DONE
