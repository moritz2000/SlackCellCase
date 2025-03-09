include <BOSL2/std.scad>
include <partsScad/partsScad.scad>

include <config.scad>
include <libs/twist_joint.scad>


heltec_edge_to_usb = 0.7;
//outer_lid_to_usb = 6.6;
outer_lid_to_usb = 8.5;

usb_hole_plug_slop = 0.7;

plug_inner_height = outer_lid_to_usb + heltec_edge_to_usb - s2_walls;
plug_dia = 15;

example_config = twist_joint_config(plug_dia, plug_inner_height, 1.5, 2, extra_angle = 10, extra_angle_internal = 10, rotate = 60, num_lips = 3);


*part("tests/usb_plug_hole.stl")ydistribute(spacing = 15) {
        diff() usb_c_covered_hole(oring_slop = 0.4);
        diff() usb_c_covered_hole(oring_slop = 0.8);
}
*right($preview ? 45 : 0)
    part("tests/usb_plug.stl") test_plug();

inner_cyl_dia = 20;
inner_cyl_height = 3;
//oring_d_min = 1.5;
oring_d_min = 2.5;


grip_height = 2.55;

//yrot(90) cube([12, 5, 8], anchor = FRONT);

module test_plug(){
    color("green") diff() twist_joint(example_config, anchor = BOTTOM, orient = UP, spin = 90, $slop = usb_hole_plug_slop){
        attach(BOTTOM, TOP)
            cyl(grip_height, d=24, anchor = BOTTOM, orient = FRONT){
                position(CENTER)
                    cuboid([8, 38, grip_height], rounding = 4, edges = "Z", anchor = CENTER);
                tag("remove") position(BOTTOM)
                    mirror(BACK)text3d("USB", h=2*layer_height, size = 7, anchor = BOTTOM, atype="ycenter", spin = 90);
            }
        tag("not_remove") attach(BOTTOM, TOP, inside = true)
            cyl(inner_cyl_height, d=inner_cyl_dia);

        tag("remove") position(BOTTOM)
            torus(d_maj = inner_cyl_dia, d_min = oring_d_min, anchor = BOTTOM);

        //offset the upper surface so there is space for a knot
        attach(TOP, TOP, inside = true)
            cyl(2, d=plug_dia - 2*s4_walls, rounding2 = -1);
        
        //make a channel to attach a keep cord
        tag("remove")position(TOP)
            torus(d_maj = 8.5, d_min = 3.2, orient = FRONT);

    }
}

usb_c_hole_dim = [8.6, s2_walls, 3.7];
module usb_c_covered_hole(with_plug = false, oring_slop = 0, anchor = FRONT, spin = 0, orient = UP){
    cuboid([25, plug_inner_height + s2_walls, 25], anchor = anchor, spin = spin, orient = orient){
        attach(FRONT, "flush")
            twist_joint(example_config, internal=true, $slop = usb_hole_plug_slop);
        attach(BACK, BACK, inside = true)
            cuboid(usb_c_hole_dim, rounding = usb_c_hole_dim.z/2, edges = "Y");
        attach(FRONT, TOP, inside = true)
            cyl(inner_cyl_height + usb_hole_plug_slop, d=inner_cyl_dia + 2* oring_slop);
        children();
    }
}
