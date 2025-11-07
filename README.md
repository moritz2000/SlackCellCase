# SlackCellCase
This repository contains the source files to generate a 3D printable case for the [SlackCell](https://github.com/philipqueen/SlackCellESP32)

# Preperation
Download this repository with the following command: 

```bash
git clone --recurse-submodules
```

Install [Openscad](https://openscad.org/downloads.html#snapshots), you want one of the developer snapshots, because they compile waaaaay faster.

To view the models, just open the file `case.scad` with openscad.

To export the models into different stl files execute the following commamd from the terminal TWO TIMES:

```bash
python libs/partsScad/multipart.py case.scad
```

# Printing
The different parts need to be printed in different materials:
hard material (e.g. PETG):
- `case.stl`
- `lid.stl`

flexible material(e.g. TPU):
- `cell_holder.stl`
- `usb_plug.stl`
- `sd_plug.stl`
- `gasket.stl`

Instead of the gasket.stl you might also print the `lid_silicon_mold.stl` in a hard material and use that to directly inject silicon on the perimeter of the lid. That probably makes a better seal than a printed gasket.

If you use PrusaSlicer you can use the preconfigured 3mf file.

If you updated your stl files, you can reload them with F5. If you see a file selector on reload without any indication of which file to select, then cancel. Instead reload the files induvidually. (Right click models in the right panel)
