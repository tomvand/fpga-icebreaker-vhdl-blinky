# A VHDL blinky on the ICEBreaker

The goal of this repository is to document the toolchain used to program a VHDL blinky on the 1BitSquared [iCEBreaker](https://docs.icebreaker-fpga.org/hardware/icebreaker/). Otherwise, I will completely forget. Minimal code is provided and all code is stolen from other repositories.

I ran my experiment on WSL2 (Ubuntu 22.04 on Windows 10) which caused additional hurdles that will be tackled here.


## References

- iCEBreaker documentation: https://docs.icebreaker-fpga.org/hardware/icebreaker/
- Yosys: open-source synthesis suite: https://github.com/YosysHQ/yosys
  - A look at the inner workings of Yosys (how does it synthesize the design?): https://yosyshq.readthedocs.io/projects/yosys/en/latest/getting_started/example_synth.html
- Yosys OSS CAD Suite: enormous set of handy, precompiled FPGA tools. The rest of this readme assumes that this toolset is installed. Do not forget to source the environment. https://github.com/YosysHQ/oss-cad-suite-build 
- GHDL Yosys plugin: this plugin adds a VHDL frontend to Yosys. https://github.com/ghdl/ghdl-yosys-plugin
  - Blinky example code: https://github.com/ghdl/ghdl-yosys-plugin/tree/master/examples/icestick/leds
  - The Usage section in the README contains all steps to synthesize and upload the example code. Some modifications need to be made to support the iCEBreaker board.
    - Fix for missing pin 27: https://github.com/YosysHQ/nextpnr/issues/1466
- iCEBreaker udev rule: https://github.com/icebreaker-fpga/icebreaker-workshop/blob/master/README.md
- .pcf file for the iCEBreaker: https://github.com/icebreaker-fpga/icebreaker-verilog-examples/blob/main/icebreaker/icebreaker.pcf
- .pcf file for the iCEBreaker: https://github.com/YosysHQ/nextpnr/blob/master/ice40/icebreaker.pcf
  - If this is included in the nextpnr installation then it should be even easier to use...


## Project setup

### Windows/WSL2

The goal of these steps is to give a working WSL2 setup access to the iCEBreaker's USB port.

- (*This step is probably not required for WSL2, only to use iceprog on Windows. I haven't tested without it, though.*): it may be necessary to install an alternative USB driver for the iCEBreaker. I did this using Zadig following the steps here: https://gojimmypi.github.io/programming-fpga-devices-from-wsl/ and testing with the DOS-version of `iceprog -t`. **Very important** in Zadig you need to check 'List All Devices' *and uncheck 'Ignore Hubs or Composite Parents'! Otherwise it might not show Interface 0, only Interface 1, and that doesn't work apparently.
- Forward the USB device to WSL2. This is documented here: https://learn.microsoft.com/en-us/windows/wsl/connect-usb . I used `winget` to install usbipd because I am lazy. Once installed, you need to perform the following steps in an admin-permission command window:
  1. `usbipd list`, there should be a USB device with hardware ID 0403:6010 (named Dual RS232-HS).
  2. `usbipd bind --hardware-id=0403:6010`. Microsoft's tutorial uses the BUSID, but I have no idea how stable that is. The downside of using the hardware id as I did is that usbipd may also bind to other FTDI chips. As far as I'm aware, this binding should be persistent.
  3. `usbipd attach --wsl --hardware-id=0403:6010`. AFAIK this need to be done every time the device is reconnected.

This ends the Windows instructions, the next steps are performed inside WSL and should also be applicable to Ubuntu/Linux in general.


### Ubuntu

#### USB device configuration

The first step is to detect that the iCEBreaker's USB can be reached. Plug in the device and use `lsusb`, this must show a USB device with ID 0403:6010.

The second problem that I ran into was that my user did not have the permissions to access this device. If you can see the device in `lsusb` then all the Windows preparations went well, but you still need to set up the udev rules in Linux. See the troubleshooting instructions here: https://github.com/icebreaker-fpga/icebreaker-workshop/blob/master/README.md . Reload the udev rules as described here, because replugging with usbipd is a hassle: https://unix.stackexchange.com/questions/39370/how-to-reload-udev-rules-without-reboot .


#### Toolchain

With that out of the way, we can proceed to the actual FPGA steps. I use the OSS-CAD-suite provided by Yosys in this project. Follow the instructions here: https://github.com/YosysHQ/oss-cad-suite-build . Download the latest release archive, extract it to a convenient place, and *don't forget to source the ./environment file whenever you want to do FPGA development!* I've added a `setup.bash` file to this repo which you can modify with the correct path. After activating the suite, your command line prompt should be prefixed with `⦗OSS CAD Suite⦘`.

With the toolchain installed (and activated), we can check that the programmer works. Run `iceprog -t` and verify that there are no error messages.

```
⦗OSS CAD Suite⦘ tom@DESKTOP-QB3F26B:~/code/fpga-icebreaker-vhdl-blinky$ iceprog -t
init..
cdone: high
reset..
cdone: low
flash ID: 0xEF 0x70 0x18 0x00
cdone: high
Bye.
```


#### Example code

In this example project, we will put a Blinky on the iCEBreaker. We need 3 things:
1. Blinky VHDL code,
2. A pin mapping for the iCEBreaker,
3. A build script.

The Blinky code is copied from here: https://github.com/ghdl/ghdl-yosys-plugin/tree/master/examples/icestick/leds (leds.vhdl and spin1.vhdl) (GPL licensed). In this example, `leds.vhdl` is equivalent to a C header, and `spin1.vhdl` is the corresponding implementation. The VHDL code specifies what the FPGA should do, but the outputs (led1 etc) are still undefined as these depend on the FPGA package and the surrounding board.

The logical names for the FPGA pins are defined in a .pcf file such as the one here for the iCEBreaker: https://github.com/icebreaker-fpga/icebreaker-verilog-examples/blob/main/icebreaker/icebreaker.pcf . The pin numbers can be found in the iCEBreaker documentation https://docs.icebreaker-fpga.org/hardware/icebreaker/ (grey boxes). The provided file uses capitalized names for the LEDs, so I've modified the .vhdl files accordingly.

The build script is adapted from here: https://github.com/ghdl/ghdl-yosys-plugin . I've added the modified lines to a shell-script, I haven't looked into making a proper Makefile yet. I'm also not sure about other build tools. A *very important* change for the iCEBreaker is that the `nextpnr-ice40` call needs to be modified. Firstly, the correct package should be selected using `--package sg48`. Secondly, there is a required flag `--up5k` to specify the exact version of the iCE40. Omitting this flag results in a 'pin 27 not found' error. See https://github.com/YosysHQ/nextpnr/issues/1466 . See `nextpcr-ice40 -h` for all options.
