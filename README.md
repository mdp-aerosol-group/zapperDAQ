# zapperDAQ

*Data Acquisition System for the NC State Electrostatic Precipitator.*

The software is intended to run on a [Raspberry PI Model 4b](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/) that is interfaced with  [Pi-Plate DAQC2](https://pi-plates.com/) module.


## Installation (Build OS and Software From Sources)

Familiarity with Linux, the Julia language, and single board computers is assumed, especially when things go wrong. Since the DAQC2 piece is specifically created for the Raspberry Pi, the build chain relies entirely on the Pi architecture. The Pi is relatively slow and troubleshooting on a slow remote platform can be tedious. 

To learn more about how the DAQ system is built, and gain more familiarity with julia, check out the [concept implementation](https://github.com/mdpetters/Julia-AFRP-DataAcquisition) also runs on a regular x86 computer. 

### Preliminaries
- Setup Raspberry Pi and Pi-Plate. 
- Install an image Raspian OS - [64 bit version](https://downloads.raspberrypi.org/raspios_arm64/images/). The install was tested with ```raspios_arm64-2020-08-24```, but should work with subsequently released versions. The 64 bit version is needed for Julia language support. Note that the DAQC2 Pi-Plate is incompatible with Ubuntu 64 bit.
- Setup the Pi so you connect to it via ssh from your personal computer. 
- Ensure that you have a local X-server installed (e.g. Xming). When connected to the pi via ssh, test it by running 

```bash
xeyes
```

In case ```xeyes``` is not installed, install it via 

```
sudo apt-get install xeyes
```

### Install Julia
[Download julia](https://julialang.org/downloads/) onto the Raspberry Pi. Use the ```Current stable release``` and ```Generic Linux on ARM, 64-bit (AArch64)``` image. The install was tested with julia-1.6. Extract the tarball and create symbolic link.

**Example Installation Procedure**

(File name may vary with julia release and username)

(1) Download with wget
```bash
wget https://julialang-s3.julialang.org/bin/linux/aarch64/1.6/julia-1.6.0-linux-aarch64.tar.gz
```

(2) Extract the files
```bash
tar xvfz julia-1.6.0-linux-aarch64.tar.gz 
```

(3) Create symbolic link
```bash
sudo ln -s /home/pi/julia-1.6.0/bin/julia /usr/bin/julia
```

(4) Test if julia runs
```bash
julia
```

you sould see

```
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.6.0 (2021-03-24)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> 
```

You can exit out with CTRL-D

### Enable Pi-Plate
(1) Enable SPI
```bash
sudo raspi-config
```
INTERFACE OPTIONS -> ENABLE SPI

Reboot.

(2) Install Pi-Plate Drivers
```bash
sudo pip3 install Pi-Plates
sudo pip3 install spi
```

### Install zapperDAQ

(1) Create a data directory
```bash
mkdir $HOME/Data
```

(2) Clone the source code
```bash
git clone https://github.com/mdpetters/zapperDAQ.git
```

(3) Change to src directory
```bash
cd zapperDAQ/src
```

(4) Instantiate project
```bash
julia --project -e 'using Pkg; Pkg.instantiate()' 
```

This only needs to be performed once.

(5) Try running the sofware
```bash
julia --project main
```

Note that startup is slow because julia needs to compile some things each time it is loaded. Latency can be reduced through a custom sysimage described below.

### Development/Troubleshooting

Running main.jl in ther REPL will bring up the GUI and start the DAQ  loop. If you want a responsive REPL while the program runs in the background, comment out the 

```julia
wait(Godot)
```

at the end of the program or click the "Stop DAQ" button. (The program will continue to run when in REPL mode, but will terminate when called from the command line).

### Precompile to reduce latency

(1) Create a large swap space by sequentiall calling the following commands. 

```bash
sudo -s
dd if=/dev/zero of=/swapfile1 bs=1024 count=8290304
chown root:root /swapfile1
chmod 0600 /swapfile1
mkswap /swapfile1 
swapon /swapfile1
free -m
CTRL-D
```

To see if the swap space was created. It is helpful to monitor resource usage via ```htop``` in a second terminal connection. It should now show an 8 GB swap space. Run the following command in the ```src``` directory of zapperDAQ

```bash
julia --project --optimize=3 -e 'using PackageCompiler; create_sysimage([:CSV, :Colors, :DAQC2Plate, :DataFrames, :Dates, :Gtk, :InspectDR, :Lazy, :NumericIO, :Printf, :Reactive], sysimage_path="sys_daq.so", precompile_execution_file="main.jl")'
```

This will bring up the gui. Stop the gui with the ```Stop DAQ``` button. PackageCompiler will create a custom [system image]((https://julialang.github.io/PackageCompiler.jl/dev/sysimages/)). This takes a lot of time.

Load the software with custom system image

```bash
julia -q --project --sysimage sys_daq.so main.jl 
```

This will bring up the gui in a few seconds.

Create a startup script ```daq.sh```

```bash
#!/bin/bash
cd $HOME/zapperDAQ/src
julia -q --project --sysimage sys_daq.so main.jl
cd $HOME
```

and 

```bash
chmod a+x daq.sh
```

Calling ```./daq.sh``` from the command line will bring up the GUI.
