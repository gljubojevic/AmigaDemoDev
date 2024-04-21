# Amiga Demo Dev
Amiga demo development framework for system friendly executable with many parts

## Demo part development
Part folders have prefix "P_" for easier distinction.

Folder [P_Example](./P_Example/) contains files for example part
- [Example.s](./P_Example/Example.s) - Part code placed in public ram section
- [Example_Data_C.s](./P_Example/Example_Data_C.s) - Part data that must be in chip ram section
- [Example_Data_P.s](./P_Example/Example_Data_P.s) - Part data that must be in public ram section
- [Example_Bss_C.s](./P_Example/Example_Bss_C.s) - Part allocation that must be in chip ram section
- [Example_Bss_P.s](./P_Example/Example_Bss_P.s) - Part allocation that must be in public ram section
Naming scheme is selected to be easier distinguish multiple open files in editor.

Each part should have labels prefix because including part puts all labels as global.  
Example part has prefix "EP_" for all labels.
Also example part has "EXAMPLE_PART" define in main demo code so part can be switched on/off.  
Based on that define sources for part are included, see main demo code [Demo.s](./Demo.s)

Each part code has three routines:
- Init - called to initialize part before starting
- VBlank - called every vertical blank or copper interrupt
- Main - called when Copper list and VBlank for part are set

Init routine must return pointers in registers
- A0 - Copper list
- A1 - VBlank routine
- A2 - Main routine

Receives in A6 - Custom Chip Address $dff000

VBlank when called receives
- A0 - frame counter pointer
- A6 - Custom Chip Address $dff000 

Main when called receives
- A0 - frame counter pointer
- A6 - Custom Chip Address $dff000 

Frame counter pointer is meant to be used for parts timing, it is increased in VBlank demo routine.

## Assemble on Amiga
Project assembles with (tested):
- ASM-One v1.49-RC2
- ASM-One v1.48
- ASM-Pro V1.18

Use following options for assembler:
- [Off] Label :
- [Off] UCase = LCase
- [On ] ; Comment

To assemble:
Add assign "AmigaDemoDev" for folder where source is located e.g.  
```
assign AmigaDemoDev: DH1:AmigaDemoDev
```
In emulators WinUAE or FS-UAE, add source folder as HDD in config with alias "AmigaDemoDev"  

In assembler use "v" to change current directory:  
```
v AmigaDemoDev:
```
Load main source "Demo.s"  
```
r Demo.s
```
Assemble  
```
a
```
Run  
```
j
```

## Project structure
- [.vscode](.vscode/) - support for development in vscode
- [P_Example](./P_Example/) - contains demo Example part
- [P_BlankVector](./P_BlankVector/) - contains demo One Blank Vector part
- [P_Logo](./P_Logo/) - contains demo Logo part
- [Include](./Include/) - all includes used by startup routine
- [Startup](./Startup/) - demo/intro startup routine
- [uae/dh0](./uae/dh0/) - emulator startup hdd
	- [c](./uae/dh0/c/) - command dir
		- UAEquit - command to quit emulator on demo exit
	- [s](./uae/dh0/s/) - startup dir
		- [startup-sequence](./uae/dh0/s/startup-sequence) - starts demo in emulator
	- Demo - demo executable to start/debug
- [Demo.s](./Demo.s) - demo main source that runs all parts

## Launch/Debug configurations
This is supported in VSCode using extension "prb28.amiga-assembly", extension is chosen to support MacOS and Windows

MacOS/Linux configurations
- FS-UAE A500+ Run, runs demo on A500+ 512K Chip, 512K Fast
- FS-UAE A500+ Debug, debug demo on A500+ 512K Chip, 512K Fast
- FS-UAE A1200 Run, runs demo on A1200 2048K Chip, 2048K Fast
- FS-UAE A1200 Debug, debug demo on A500+ 2048K Chip, 2048K Fast

Windows configurations
- WinUAE A500+ Run, runs demo on A500+ 512K Chip, 512K Fast
- WinUAE A500+ Debug, debug demo on A500+ 512K Chip, 512K Fast

NOTE: this is not tested and might need fixing