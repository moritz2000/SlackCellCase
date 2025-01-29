include <BOSL2/std.scad>
include <BOSL2/screws.scad>

s_beam_dim = [76.2, 50.8, 25.4];
cutout_width = 10.4;
cutout_length = 37.8; //TODO
cutout_to_edge = 13.5; 

eps = 0.01;

cable_dia = 5.3;
cable_bend = 34; //outer dia of the bend cable
load_cell_cable_nut_width = 12;
load_cell_cable_angle = -22;

//load_cell();

module load_cell(screw_ons = true) {
    tag_diff("load_cell") recolor("grey") cube(s_beam_dim, anchor = CENTER){
        if(screw_ons){
            //nuts
            attach([LEFT, RIGHT], BOTTOM) nut("M16", thickness = 12.5, thread = "none")
                //eyes
                attach(TOP, BOTTOM) cyl(14, d1 = 32.5, d2 = 27)
                    attach(TOP, LEFT, shiftout = -$parent_size.z) torus(id = 39, od = 62.3, orient=DOWN);
            //nut and cable
            position(FRONT + TOP) down(8) cyl(12, d= 12, circum = true, anchor = BOTTOM, spin = load_cell_cable_angle, orient = FRONT, $fn = 6){
                //taper to the cable
                attach(TOP, BOTTOM) cyl(6.5, d1 = 11.3, d2=9);
                //cable
                recolor([0, 0, 0, 0.5]) position(TOP){
                    right(cable_dia/2) top_half()
                        torus(od = cable_bend, d_min = cable_dia, $fn = 12, anchor = RIGHT, orient = FRONT);
                    position(CENTER) left(cable_bend - cable_dia) cyl(50, d = cable_dia, anchor = BOTTOM, orient = DOWN, $fn = 12);
                }
            }
        }
        //cutouts
        tag("remove") zrot_copies(n = 2) align(FRONT, RIGHT, inside=true, shiftout = eps) left(cutout_to_edge)//TODO position
            cuboid([cutout_width, cutout_length + eps, s_beam_dim.z + eps], rounding = cutout_width/2, edges = [BACK + LEFT, BACK + RIGHT]);
    }
}