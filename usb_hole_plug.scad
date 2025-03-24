include <BOSL2/std.scad>
include <partsScad/partsScad.scad>
include <BOSL2/threading.scad>

*part("tests/usb_plug_hole.stl"){
        diff() threaded_plug_hole();
}
*right($preview ? 45 : 0)
    part("tests/usb_plug.stl") threaded_plug();

//profile copied from the pipe thread module npt_threaded_rod()
function profile(pitch, internal) = 
    let(depth = pitch * cos(30) * 5/8)
        internal ? [
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

//od = 17; //20 was the old value, where I already have a plug, can I use that one for the sd (while obviously having the wrong label on it ;)

//has to be smaller, because it is longer, and the result should be the same thread just extended

//grip_dia = 22; //24 old value, maybe for sd?

//when the plug is screwed in completely this amount will remain in z direction between plug and hole
function thread_config(thread_od, plug_inner_height, thread_decrease_d = 1, pitch = 2, external_to_internal_thread_z_gap = 0.6) = 
    let(
        id = thread_od - thread_decrease_d,
        outer_thread_height = plug_inner_height - external_to_internal_thread_z_gap,
        internal_thread_height = plug_inner_height + 2*eps,
        id_internal = thread_od - (thread_od - id)/outer_thread_height * internal_thread_height
    )
        struct_set([], [
            "thread_od", thread_od,
            "plug_inner_height", plug_inner_height,
            "thread_id", id,
            "outer_thread_height", outer_thread_height,
            "internal_thread_height", internal_thread_height,
            "id_internal", id_internal,
            "pitch", pitch,
            "external_to_internal_thread_z_gap", external_to_internal_thread_z_gap
        ]);

module threaded_plug(thread_config, grip_dia = 22, grip_height = 4, straight_height_before_grip_flanges = 0, flange_length = 7, flange_width = 8, text = "", anchor = CENTER, spin = 0, orient = UP){
    thread_od = struct_val(thread_config, "thread_od");
    plug_inner_height = struct_val(thread_config, "plug_inner_height");
    id = struct_val(thread_config, "thread_id");
    outer_thread_height = struct_val(thread_config, "outer_thread_height");
    internal_thread_height = struct_val(thread_config, "internal_thread_height");
    id_internal = struct_val(thread_config, "id_internal");
    pitch = struct_val(thread_config, "pitch");

    attachable(anchor, spin, orient, d=grip_dia, h=grip_height + internal_thread_height){
        position(TOP) diff() generic_threaded_rod(
                d1=thread_od, d2=id, l=outer_thread_height,
                pitch=pitch,
                profile=profile(pitch, false),
                left_handed=false,
                internal=false,
                blunt_start=true,
                anchor = TOP
        ){
            attach(BOTTOM, TOP) 
                cyl(straight_height_before_grip_flanges + grip_height, d = grip_dia, anchor = BOTTOM, orient = FRONT){
                    position(BOTTOM)
                        cuboid([flange_width, grip_dia + 2*flange_length, grip_height], rounding = flange_width/2, edges = "Z", anchor = BOTTOM);
                    tag("remove") position(BOTTOM)
                        mirror(BACK)text3d(text, h=0.6, size = 7, anchor = BOTTOM, atype="ycenter", spin = 90);
                }

            //offset the upper surface so there is space for a knot
            attach(TOP, TOP, inside = true)
                cyl(2, d=id - 2*s4_walls, rounding2 = -1);
            
            //make a channel to attach a keep cord
            tag("remove")position(TOP)
                torus(d_maj = 8.5, d_min = 3.2, orient = FRONT);
        }
        children();
    }
}

module threaded_plug_hole(thread_config, hole_dim, wall_height, wall_z_offset = 0, rounding = case_rounding, edges = "Y", anchor = FRONT, spin = 0, orient = UP){
    thread_od = struct_val(thread_config, "thread_od");
    plug_inner_height = struct_val(thread_config, "plug_inner_height");
    id = struct_val(thread_config, "thread_id");
    outer_thread_height = struct_val(thread_config, "outer_thread_height");
    internal_thread_height = struct_val(thread_config, "internal_thread_height");
    id_internal = struct_val(thread_config, "id_internal");
    pitch = struct_val(thread_config, "pitch");

    up(wall_z_offset) cuboid([thread_od + 2*s6_walls, plug_inner_height + s2_walls, wall_height], rounding = rounding, edges = edges, anchor = anchor, spin = spin, orient = orient){
        down(wall_z_offset){
            fwd(eps) attach(FRONT, BOTTOM, inside = true)
                generic_threaded_rod(
                    d1=thread_od, d2=id_internal, l=internal_thread_height,
                    pitch=pitch,
                    profile=profile(pitch, true),
                    left_handed=false,
                    internal=true,
                    blunt_start=true
                );
            //hole connecting up to the data port
            attach(BACK, BACK, inside = true, shiftout = eps)
                cuboid(hole_dim + [0, eps, 0], rounding = hole_dim.z/2, edges = "Y");
        }
        children();
    }
}
