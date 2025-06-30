# Stop on error
set -e

# Analyse VHDL sources
ghdl -a leds.vhdl
ghdl -a spin1.vhdl

# Synthesize the design.
# NOTE: if GHDL is built as a module, set MODULE to '-m ghdl' or '-m path/to/ghdl.so',
#       otherwise, unset it.
yosys -m ghdl -p 'ghdl leds; synth_ice40 -json leds.json'

# P&R
nextpnr-ice40 --up5k --package sg48 --pcf icebreaker.pcf --asc leds.asc --json leds.json

# Generate bitstream
icepack leds.asc leds.bin

# Program FPGA
iceprog leds.bin
