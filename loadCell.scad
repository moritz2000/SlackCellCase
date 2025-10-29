include <libs/BOSL2/std.scad>
include <libs/BOSL2/screws.scad>

//Dimensions of PSD-S1 s-beam load cell, as defined by manufacturer, and measured for the cutout.
//Datasheet can be found here: http://www.pushton.com/?m=home&c=View&a=index&aid=122
loadcell_dim = [76.2, 50.8, 25.4];
loadcell_cutout_width = 10.4;
loadcell_cutout_length = 37.8;
loadcell_cutout_to_edge = 13.5; 

//This characterizes the form of the cable when mounted inside the case.
//Has to be close to reality, because the cable channel is build automatically from the geometry in module loadcell_cable, which uses these values
loadcell_cable_dia = 5.3;
loadcell_cable_bend = 34; //outer dia of the bent cable
loadcell_cable_nut_width = 12;
loadcell_cable_angle = -22;
//offset from upper surface of loadcell to the middle of the nut
loadcell_cable_z_offset = 8;

//fudge factor to prevent differences looking weird in preview
eps = 0.01;

//load_cell();

module loadcell_cable(){
    down(loadcell_cable_z_offset)
        cyl(12, d= 12, circum = true, anchor = BOTTOM, spin = loadcell_cable_angle, orient = FRONT, $fn = 6){
            //taper to the cable
            attach(TOP, BOTTOM) cyl(6.5, d1 = 11.3, d2=9);
            //cable
            recolor("black") position(TOP){
                right(loadcell_cable_dia/2) top_half()
                    torus(od = loadcell_cable_bend, d_min = loadcell_cable_dia, $fn = 12, anchor = RIGHT, orient = FRONT);
                position(CENTER) left(loadcell_cable_bend - loadcell_cable_dia) cyl(50, d = loadcell_cable_dia, anchor = BOTTOM, orient = DOWN, $fn = 12);
            }
        }
}

module load_cell(screw_ons = true, show_s_beam = true) {
    tag_diff("load_cell") recolor("grey") maybe_cube(loadcell_dim, show=show_s_beam, anchor = CENTER) recolor("grey"){
        if(screw_ons){
            //nuts
            attach([LEFT, RIGHT], BOTTOM) nut("M16", thickness = 12.5, thread = "none")
                //eyes
                attach(TOP, BOTTOM) cyl(14, d1 = 32.5, d2 = 27)
                    attach(TOP, LEFT, shiftout = -$parent_size.z) torus(id = 39, od = 62.3, orient=DOWN);
            //nut and cable
            position(FRONT + TOP) loadcell_cable();
        }
        //cutouts
        tag("remove") zrot_copies(n = 2) align(FRONT, RIGHT, inside=true, shiftout = eps) left(loadcell_cutout_to_edge)
            cuboid([loadcell_cutout_width, loadcell_cutout_length + eps, loadcell_dim.z + eps], rounding = loadcell_cutout_width/2, edges = [BACK + LEFT, BACK + RIGHT]);
    }
}

//this is a cube, that can be hidden, while still keeping it's children
module maybe_cube(size, show = true, anchor = CENTER, spin = 0, orient = UP){
    attachable(anchor, spin, orient, size = size){
        if(show)
            cube(size, anchor = CENTER);
        children();
    }
}
