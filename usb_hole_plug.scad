include <BOSL2/std.scad>
include <partsScad/partsScad.scad>
include <BOSL2/threading.scad>

include <config.scad>

outer_lid_to_usb = case_outer_dim_xy.y/2 + pcb_usb_position.x;

usb_hole_plug_slop = 0.7;

plug_inner_height = outer_lid_to_usb - s2_walls;
plug_dia = 15;

//when the plug is screwed in completely this amount will remain in z direction between plug and hole
usb_external_to_internal_thread_gap = 0.6;


*part("tests/usb_plug_hole.stl")ydistribute(spacing = 15) {
        diff() usb_c_covered_hole();
}
*right($preview ? 45 : 0)
    part("tests/usb_plug.stl") test_plug();

inner_cyl_dia = 20;
inner_cyl_height = 3;

grip_height = 4;

//yrot(90) cube([12, 5, 8], anchor = FRONT);
internal = false;
pitch = 2;
depth = pitch * cos(30) * 5/8;

//profile copied from the pipe thread module npt_threaded_rod()
function profile(internal) = internal ? [
    [-6/16, -depth/pitch],
    [-1/16,  0],
    [-1/32,  0.02],
    [ 1/32,  0.02],
    [ 1/16,  0],
    [ 6/16, -depth/pitch]
] : [
    [-7/16, -depth/pitch*1.07],
    [-6/16, -depth/pitch],
    [-1/16,  0],
    [ 1/16,  0],
    [ 6/16, -depth/pitch],
    [ 7/16, -depth/pitch*1.07]
];

od = 17; //20 was the old value, where I already have a plug, can I use that one for the sd (while obviously having the wrong label on it ;)
id = od - 1;

//has to be smaller, because it is longer, and the result should be the same thread just extended
outer_thread_height = plug_inner_height - usb_external_to_internal_thread_gap;
internal_thread_height = plug_inner_height + 2*eps;
id_internal = od - (od - id)/outer_thread_height * internal_thread_height;

grip_dia = 22; //24 old value, maybe for sd?

module test_plug(anchor = CENTER, spin = 0, orient = UP){
    attachable(anchor, spin, orient, d=grip_dia, h=grip_height + internal_thread_height){
        position(TOP) diff() generic_threaded_rod(
                d1=od, d2=id, l=plug_inner_height - usb_external_to_internal_thread_gap,
                pitch=pitch,
                profile=profile(false),
                left_handed=false,
                internal=false,
                blunt_start=true,
                anchor = TOP
        ){
            attach(BOTTOM, TOP)
                cyl(grip_height, d = grip_dia, anchor = BOTTOM, orient = FRONT){
                    position(CENTER)
                        cuboid([8, 38, grip_height], rounding = 4, edges = "Z", anchor = CENTER);
                    tag("remove") position(BOTTOM)
                        mirror(BACK)text3d("USB", h=2*layer_height, size = 7, anchor = BOTTOM, atype="ycenter", spin = 90);
                }

            //offset the upper surface so there is space for a knot
            attach(TOP, TOP, inside = true)
                cyl(2, d=plug_dia - 2*s4_walls, rounding2 = -1);
            
            //make a channel to attach a keep cord
            tag("remove")position(TOP)
                torus(d_maj = 8.5, d_min = 3.2, orient = FRONT);
        }
        children();
    }
}

usb_c_hole_dim = [8.6, s2_walls + eps, 3.7];

module usb_c_covered_hole(anchor = FRONT, spin = 0, orient = UP){
    cuboid([od + 2*s6_walls, plug_inner_height + s2_walls, (-pcb_usb_position.z + lid_to_display_dist + case_wall)*2], rounding = case_rounding, edges = "Y", anchor = anchor, spin = spin, orient = orient){
        fwd(eps) attach(FRONT, BOTTOM, inside = true)
            generic_threaded_rod(
                d1=od, d2=id_internal, l=internal_thread_height,
                pitch=pitch,
                profile=profile(true),
                left_handed=false,
                internal=true,
                blunt_start=true
            );
        //hole connecting up to the usb c port
        attach(BACK, BACK, inside = true, shiftout = eps)
            cuboid(usb_c_hole_dim, rounding = usb_c_hole_dim.z/2, edges = "Y");

        children();
    }
}
