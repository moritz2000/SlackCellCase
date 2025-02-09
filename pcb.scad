//sources for the cad files:
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

pcb_size = [50, 70];
bottom_pcm_to_display_height = 14.5;

module pcb(anchor = CENTER, spin = 0, orient = UP){
    attachable(anchor, spin, orient, size = [pcb_size.x, pcb_size.y, bottom_pcm_to_display_height]){
        position(BOTTOM + LEFT + FRONT) up(1.5){
            move([53.7261, -18.17185]) xrot(-90) recolor("green") import("GrabCad/universal_board_50x70mm-1.snapshot.2/Universal_board_50x70mmFreeCad.stl");

            move([0.6, 29.8, -8 + 6.5]) xrot(90)
                recolor("orange") import("GrabCad/esp32-wifi-lora-1.snapshot.15/ESP32 Heltec WIFI.STL");
            move([12.275, 72.3])  zrot(180) difference(){
                recolor("blue") import("GrabCad/tf-micro-sd-card-memory-modul-arduino-1.snapshot.3/Product_TF Micro SD Card Memory Modul Arduino.stl");
                translate([-10, 37, 4.5]) cube([20, 10, 4]);
            }

            move([27.55, 65.7, 0]) zrot(-90) recolor("darkgreen") import("GrabCad/HX711/HX711.stl");
        }
        children();
    }
}

