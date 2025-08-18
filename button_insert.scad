include <BOSL2/std.scad>
include <config.scad>
include <pcb.scad>

include <partsScad/partsScad.scad>
button_insert();

button_hole_xy_gap = 0.1;
button_hole_moving_gap = 0.25;
button_to_lid_top = 6.9;
button_gap_till_pressed = 0.2;
button_lip = s4_walls;
button_top_wall = 0.75;
button_bottom_wall = 1;
button_inset_wall = 0.7;
button_stud_dia = 4;

button_moving_overlap = 0.8;

button_user_stickout = 0.5;

gluing_part_height = 1;

module button_insert() part("button_insert.stl"){
    //p = pcb_button_positions[0];
    upper_tube_dia = button_hole_dia - 2*button_hole_xy_gap;
    upper_moving_tube_dia = button_hole_dia - 2*button_hole_moving_gap;
    inside_sphere_dia = upper_tube_dia - 2*button_inset_wall;
    bottom_cyl_height = button_to_lid_top - case_wall - button_gap_till_pressed;
    bottom_chamber_chamfer = bottom_cyl_height - button_top_wall - button_bottom_wall;
    diff()
        for(p = pcb_button_positions)
        up(lid_to_display_dist) move(p){
            //part of the inset thats inside the case holes
            cyl(gluing_part_height, d = upper_tube_dia, anchor = BOTTOM)
                position(TOP)
                    tag("remove") up(eps)
                        cyl($parent_size.z + button_top_wall + 2*eps, d=$parent_size.x - 2*button_inset_wall, chamfer1 = bottom_chamber_chamfer - button_lip - button_hole_xy_gap, anchor = TOP);
            //button lip
            cyl(bottom_cyl_height, d= button_hole_dia + 2*button_lip, anchor = TOP){
                attach(TOP, TOP, inside = true, shiftout = -button_top_wall)
                    //cutout with chamfer for supportless printing
                    cyl($parent_size.z - button_top_wall - button_bottom_wall, d= $parent_size.x - 2* button_inset_wall, chamfer2 = bottom_chamber_chamfer);
                position(BOTTOM)
                    tag("keep")
                        cyl(button_to_lid_top - button_gap_till_pressed - button_moving_overlap, d=button_stud_dia, chamfer2 = -(upper_moving_tube_dia - button_stud_dia)/2, anchor = BOTTOM)
                            attach(TOP, BOTTOM)
                                cyl(button_user_stickout + button_moving_overlap, d=upper_moving_tube_dia);
            }
        }
}