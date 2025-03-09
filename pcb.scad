//sources for the cad files:
//all simplified with https://github.com/fogleman/simplify
//sd module:
//https://grabcad.com/library/tf-micro-sd-card-memory-modul-arduino-1

//Heltec dev board
//https://grabcad.com/library/esp32-wifi-lora-1

//HX711
//https://grabcad.com/library/hx711-15

//grid pcb
//https://grabcad.com/library/universal_board_50x70mm-1
include <BOSL2/std.scad>

//pcb() show_anchors();
//x and y are the measurements for the grid pcb, not taking into account the few parts that stick out on the edge
//z is the distance from the bottom of the pcb to the TOP of the display
pcb_dim = [50, 70, 14.5];
pcb_thickness = 1.5;


//Section for defining the positions of the screw holes on the pcb
pcb_hole_center_to_edge_dist = 1.8;
pcb_hole_x_offset = pcb_dim.x/2 - pcb_hole_center_to_edge_dist;
pcb_hole_y_offset = pcb_dim.y/2 - pcb_hole_center_to_edge_dist;
pcb_hole_z_offset = -pcb_dim.z + pcb_thickness;

//positions of the screw holes relative to TOP of pcb()
pcb_screw_holes = [
    [pcb_hole_x_offset, pcb_hole_y_offset, pcb_hole_z_offset],
    [-pcb_hole_x_offset, -pcb_hole_y_offset, pcb_hole_z_offset],
    [pcb_hole_x_offset, -pcb_hole_y_offset, pcb_hole_z_offset],
    //one of the screw holes is offset, because its the hole of the sd card module and sticks out over the grid pcb hole
    [-pcb_dim.x/2 + 2, pcb_dim.y/2, pcb_hole_z_offset + 1.25]
];

//position of the middle top of the screen relative to pcb assembly TOP
pcb_display_pos = [pcb_dim.x/2-18.6, -pcb_dim.y/2 + 17.9, 0];


pcb_button_y_offset = pcb_dim.y/2 - 24.5;
pcb_button_z_offset = 1.75;

//generate the 4 buttons with even spacing in between
pcb_button_positions = line_copies(
    n = 4, //we have four buttons
    p1=[pcb_dim.x/2 - 7, 0, 0], //the left most is 7mm from the left edge
    p2=[-pcb_dim.x/2 + 5.5, 0, 0], //the right most is 5.5mm from the right edge
    p=[0,pcb_button_y_offset,pcb_button_z_offset] //y and z position of all buttons relative to TOP of pcb assembly
);

//Center point of the plug side of the usb relative to TOP of the pcb assembly
pcb_usb_position = [-pcb_dim.x/2 -0.5, -pcb_dim.y/2 + 18, -3.95];




//show pcb including the screw points
*pcb()
    position(TOP){
        for(p = pcb_screw_holes)
            move(p) #sphere(d=5);
    }


//should be placed at TOP of pcb assembly
module pcb_button_board(){
    recolor("green") down(5) back(pcb_dim.y/2 - 12.2) cube([52, 19.8, 1.2], anchor = TOP + BACK);
    for(p = pcb_button_positions)
        move(p) recolor("black") cyl(2.8, d=3.2, anchor = TOP)
            attach(BOTTOM, TOP)
                recolor("grey") cube([5.9, 5.9, 4.6]);
}

module pcb(anchor = CENTER, spin = 0, orient = UP){
    attachable(anchor, spin, orient, size = pcb_dim){
        union(){
            position(BOTTOM + LEFT + FRONT) up(1.5){
                move([53.7261, -18.17185]) xrot(-90) color("green") import("GrabCad/universal_board_50x70mm-1.snapshot.2/Universal_board_50x70mmFreeCad_simple.stl");

                move([0.6, 29.8, -8 + 6.5]) xrot(90)
                    color("orange") import("GrabCad/esp32-wifi-lora-1.snapshot.15/ESP32 Heltec WIFI_simple.STL");
                move([12.275, 72.3])  zrot(180) difference(){
                    color("blue") import("GrabCad/tf-micro-sd-card-memory-modul-arduino-1.snapshot.3/Product_TF Micro SD Card Memory Modul Arduino_simple.stl");
                    translate([-10, 37, 4.5]) cube([20, 10, 4]);
                }

                move([27.55, 65.7, 0]) zrot(-90) color("darkgreen") import("GrabCad/HX711/HX711_simple.stl");
            }
            position(TOP){
                pcb_button_board();
                move(pcb_usb_position) cyl(6.6, d=15, anchor = BOTTOM, orient = LEFT);
            }
        }
        children();
    }
}

