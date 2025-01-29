include <BOSL2/std.scad>
include <BOSL2/screws.scad>


nut_info = nut_info("M16", thickness = 12.5, thread="none");
other_wall = 3; //TODO adjust for a existing test plate?


interface_dia = 30;
chamfer = 1; //given by next drill bit size

flange_thickness = 2.5; //TODO: should be the loadcell to case gap
flange_overlap = chamfer; //TODO
flange_outer_dia = interface_dia + 2*flange_overlap;


tag_diff("nut-gasket"){
    cyl(other_wall, d=interface_dia, chamfer = -1){
        attach(TOP, BOTTOM)
            cyl(flange_thickness, d= flange_outer_dia);
        //make space for the nut, no tolerance because of TPU
        tag("remove") hull() nut(nut_info, anchor = CENTER);
    }
}

cube_thin_wall = 2.21;
cube_thick_wall = 3.28;

cube_size = 35;

!diff() cube([15, cube_size, cube_size]) tag("remove"){
    attach(RIGHT, LEFT, inside = true)cube([$parent_size.x - cube_thick_wall, $parent_size.y - 2*cube_thin_wall, $parent_size.z - 2*cube_thin_wall]);
    attach(LEFT, BOTTOM, inside = true) cyl(cube_thick_wall*2, d=interface_dia-1); //intended to be drilled open
}