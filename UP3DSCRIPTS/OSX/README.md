# UP3D AppleScript

This is an apple script app to make the printing of G-code files easy.
The app can be started and it asks then for a G-Code file, it supports
drag and drop of G-Code files and it can be integrated with e.g. Slic3r.
Simply download *print_up3d.pkg* and install it with a double click.
The application is then located in the */Application* folder.

When you start *printer_up3d.app* the first time it will gradually ask
for the executables of *up3dtranscoder* and *upload*.

The app asks for the nozzle height and saves this value for the next time.
It shows you always the last used nozzle height and you can modify it in
case you need to.


## Installing the app in Slic3er

1. copy the launch script *print_up3d.sh* to place you remember
2. make it executable via Terminal with the command `chmod +x print_up3d.sh`
3. go to Print Settings / Output options / Post-processing scripts
4. enter the full path of the script e.g. `/Users/myself/Desktop/print_up3d.sh`


## Installing for other slicers (like Cura, Simplify3D, …)

1. install the package *print_up3d.pkg* in the */Applications* folder
2. in Terminal `cp /Application/print_up3d.app ~/Library/Scripts/Folder\ Action\ Scripts`
3. create an extra output folder like `UP3D prints`
4. right-click on that folder and configure folder actions, adding *print_up3d* to it,
   activate the folder action
5. now when you place a g-code file (with ending .gcode, .g, .go, .gc) to the folder the
   app should start automatically

## delete default values 

*print_up3d* uses some defaults in order to save the nozzle height and location of transcoder and uploader. When you delete those defaults the script will ask again for the location of the executables. Use the following command to delete all the defaults for the script:

`defaults delete com.up3d.transcode`

Then launch *print_up3d.app* again for assigning new values.


## Notes for building the app and package

Use Apple Script Editor to open the *print_up3d.applescipt* file.
Export the file as Application and save it.
Move *print_up3d.app* to the desired location, e.g. */Applications*.
Later the install package will use this location for deployment.
In Terminal build the package with the command:

`productbuild --component /Applications/print_up3d.app print_up3d.pkg`
