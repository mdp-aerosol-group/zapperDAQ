# +
# plot_helpers.jl
#
# collection of routines to initialize graphs for the UI
#
# function push_plot_to_gui!(plot, box, wnd)
# -- adds the plot to a Gtk box located in a window
#
# function refreshplot(gplot::InspectDR.GtkPlot)
# -- refreshes the Gtk plot on screen
#
# function addpoint!(x::Float64,y::Float64,plot::InspectDR.Plot2D,
#  				     gplot::InspectDR.GtkPlot)
# -- adds an x/y point to the plot
#
# function graphXX()
# -- setup of the frame for a particular GUI plot

import NumericIO:UEXPONENT

function graph1()
	plot = InspectDR.transientplot(:log, title="")
	InspectDR.overwritefont!(plot.layout, fontname="Helvetica", fontscale=1.4)
	plot.layout[:enable_legend] = true
	plot.layout[:halloc_legend] = 90
	plot.layout[:halloc_left] = 50
	plot.layout[:enable_timestamp] = false
	plot.layout[:length_tickmajor] = 10
	plot.layout[:length_tickminor] = 6
	plot.layout[:format_xtick] = InspectDR.TickLabelStyle(UEXPONENT)
	plot.layout[:frame_data] =  InspectDR.AreaAttributes(
         line=InspectDR.line(style=:solid, color=black, width=0.5))
	plot.layout[:line_gridmajor] = InspectDR.LineStyle(:solid, Float64(0.75), 
													   RGBA(0, 0, 0, 1))

	plot.xext = InspectDR.PExtents1D()
	plot.xext_full = InspectDR.PExtents1D(0, 205)

	graph = plot.strips[1]
	graph.grid = InspectDR.GridRect(vmajor=true, vminor=false, 
								hmajor=true, hminor = false)
	graph.yext = InspectDR.PExtents1D() 
	graph.yext_full = InspectDR.PExtents1D(10, 10000)

	a = plot.annotation
	a.xlabel = ""
	a.ylabels = [""]

	return plot
end

# -- adds an x/y point to the plot
function addpoint!(x::Float64,y::Float64,plot::InspectDR.Plot2D,
				   gplot::InspectDR.GtkPlot,strip::Int)
	
	push!(plot.data[strip].ds.x,x)
	push!(plot.data[strip].ds.y,y)
	cut = plot.data[strip].ds.x[end]-bufferlength
	ii = plot.data[strip].ds.x .<= cut
	deleteat!(plot.data[strip].ds.x, ii)	
	deleteat!(plot.data[strip].ds.y, ii)
	plot.xext = InspectDR.PExtents1D()
	plot.xext_full = InspectDR.PExtents1D(plot.data[strip].ds.x[1],
										  plot.data[strip].ds.x[end])

	refreshplot(gplot)
end

# -- adds the plot to a Gtk box located in a window
function push_plot_to_gui!(plot::InspectDR.Plot2D, 
						   box::GtkBoxLeaf, 
						   wnd::GtkWindowLeaf)

	mp = InspectDR.Multiplot()
	InspectDR._add(mp, plot)
	grd = Gtk.Grid()
	Gtk.set_gtk_property!(grd, :column_homogeneous, true)
	status = _Gtk.Label("")
	push!(box, grd)
	gplot = InspectDR.GtkPlot(false, wnd, grd, [], mp, status)
	InspectDR.sync_subplots(gplot)
	return mp,gplot
end

# -- setup of the frame for a particular GUI plot
# Traced from InspectDR source code without title refresh
function refreshplot(gplot::InspectDR.GtkPlot)
	if !gplot.destroyed
        set_gtk_property!(gplot.grd, :visible, false) 
        InspectDR.sync_subplots(gplot)
		for sub in gplot.subplots
			InspectDR.render(sub, refreshdata=true)  
		    Gtk.draw(sub.canvas)
		end
        set_gtk_property!(gplot.grd, :visible, true)
        Gtk.showall(gplot.grd)
        sleep(eps(0.0))
	end
end
