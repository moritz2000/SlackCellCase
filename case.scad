include <BOSL2/std.scad>
include <BOSL2/screws.scad>
include <BOSL2/rounding.scad>

include <partsScad/partsScad.scad>

include <loadCell.scad>
include <pcb.scad>
include <battery.scad>

include <config.scad>
include <usb_hole_plug.scad>
include <libs/stl_modifier.scad>

*screw_and_water_test();
*lid_seal();
*lid_test();

//material saving test for screw hole position and display 
module lid_test(only_screen = false) part("tests/pcb_screws.stl"){
    intersection(){
        diff(){
            pcb_screws();
            pcb_display_window(include_window = true);
            pcb_button_holes();
            pcb_dev_board_pushers();
            up(lid_to_display_dist) multmatrix(pcb_transform_matrix)
                //flipped upside to to have fance teardrop rounding for a test part ...
                cuboid([60, 80, case_wall], rounding = case_rounding, edges = [BOTTOM, "Z"], teardrop=true, anchor = TOP, orient=DOWN);
        }
        if(only_screen)
            multmatrix(pcb_transform_matrix) move(pcb_display_pos) left(3) cube([50, 30, 30], anchor = CENTER);
    }
}

//When rendering in OpenSCAD, explode the parts sideways up to be able to differentiate them.
//final export is done through partsScad, and during that the exploding is deactivated
//More information on how to export this project to distinct stl files: https://web.archive.org/web/20221117221043/https://traverseda.github.io/code/partsScad/index.html
xdistribute(spacing = ($preview || multiPartOutput != false) ? 0 : render_spacing){
    case(anchor = TOP);
    
    cell_holders(anchor = TOP);

    gasket(anchor = BOTTOM);

    up(gasket_thickness)
        lid(anchor = BOTTOM);

    if($preview)
        %multmatrix(pcb_transform_matrix) pcb(anchor = TOP)
            attach(BOTTOM, TOP)
                fwd(8) up(pcb_to_battery_spacing)
                    battery(spin = -90);
    
    //representation of the screws
    *%up(eps)
        case_clamping_screws(lower = false, upper = false, screw = true);

    //representation of the loadcell with all connected hardware
    %down(cell_to_case_gap_z + loadcell_dim.z/2)
        load_cell(show_s_beam = true);

}

//corner piece which allows the loadcell to move while being inside the housing
module cell_holders(anchor = CENTER, spin = 0, orient = UP) {
    attachable(anchor, spin, orient, size = [case_inner_dim_xy.x - 2*loadcell_cutout_to_edge - 2*loadcell_cutout_width, case_inner_dim_xy.y, case_inner_dim_z]){
        zrot_copies(n=2){
            move([loadcell_dim.x/2 - loadcell_cutout_to_edge -loadcell_cutout_width , -loadcell_dim.y/2] + [cell_to_case_gap_xy, -cell_to_case_gap_xy]) 
                mirror_copy(RIGHT, cp = [loadcell_cutout_width/2 - cell_to_case_gap_xy, 0, 0]) rotate(-90)
                    cell_holder();
        }
        children();
    }
}

module cell_holder() part("cell_holder.stl") recolor("white"){
    difference(){
        cuboid( [cell_holder_width, cell_holder_width , case_inner_dim_z], anchor = RIGHT + BACK);
        //Using the reference of the loadcell to make a perfectly fitting cutout in the holder.
        //And because it is printed out of TPU it doesn't need tolerances.
        translate([-case_inner_dim_xy.x/2, -case_inner_dim_xy.y/2])
            load_cell(screw_ons=false);
    }
}

module pcb_display_window(include_window = false){
    module window(cutter=false){
        //execute intersection in 3d to generate less objects in CSG Tree
        frame_map(z=[1, 0, 0], y=[0, 0, 1]) linear_extrude(window_dim.x + (cutter ? 2*window_slop : 0), center = true) intersection(){
            square([window_dim.y, window_dim.z] + (cutter ? 2*repeat(window_slop, 2) : [0, 0]), anchor = FRONT);
            back(window_dim.z)
                if(cutter)
                    circle(d=window_radius, anchor = BACK);
                else
                    ring(d2=window_radius, d1 = window_radius - 2*2.95, anchor = BACK);
        }
    }
    
    multmatrix(pcb_transform_matrix) move(pcb_display_pos) up(display_to_window_dist){
        cube(window_dim + 2*[window_holder_wall, window_holder_wall, 0], anchor = BOTTOM);
        if(include_window)
            %window();
        tag("remove"){
            window(cutter=true);
            cube(window_dim - 2*window_border, anchor = BOTTOM);
        }
    }
}

module pcb_button_holes(){
    multmatrix(pcb_transform_matrix)
        tag("remove") for(p = pcb_button_positions)
            move(p) cyl(10, d=10.5, anchor = BOTTOM);
}

module pcb_dev_board_pushers(){
    multmatrix(pcb_transform_matrix){
        ycopies(spacing = -9*2.54, n = 2, sp = 0)
            move([-pcb_dim.x/2 + 5.5, -pcb_dim.y/2 + 28.5, lid_to_display_dist]) cube([9, s4_walls, lid_to_display_dist + 3.5], anchor = TOP + LEFT);
        move([pcb_dim.x/2 - 0.5, -pcb_dim.y/2 + 17, lid_to_display_dist]) cuboid([2.5, 14, lid_to_display_dist + 5.2], anchor = TOP);
    }
}

module lid_seal(){
    seal_width = 3;
    seal_corner_chamfer = 10;
    force_tag("lid_seal") up(10) scale([1, 1, -2]) roof()
        diff() rect(case_inner_dim_xy + 2*repeat(seal_width, 2), anchor = CENTER, chamfer = seal_corner_chamfer)
            tag("remove")rect(case_inner_dim_xy - 2*repeat(seal_width, 2), anchor = CENTER, chamfer = seal_corner_chamfer - seal_width);
}

//For M3 nut insert

case_screw_chamfer = 6;

case_clamping_middle_offset = case_outer_dim_xy.x/2 - 3;

case_screw = screw_info(str("M3,", 16), head = "socket", drive="hex", shaft_oversize = 0.9, head_oversize = 0.85, thread="none");
case_nut = nut_info("M3", shape = "hex", thickness = 2.2);

//this moves one of the screw holes to be not in the way of the cable of the load cell
cable_screw_position = [-14, -case_outer_dim_xy.y/2 - 6];

//this includes needed support and cutaways for a screw attachment
//at the height of the anchor point is the change between screw hole (above) and threaded insert (below)
module case_clamping_screws(positive = true, negative = true, upper = false, lower = false, screw = false){
    //wrap the screw_point module into an extra module to be able to change parameters in one point only
    module normal_case_screw(){
        screw_point(case_screw, case_nut, positive, negative, upper, lower, gap = gasket_thickness, screw = screw, edges = BOTTOM, except_edges = BOTTOM + LEFT)
            children();
    }
    //All corners
    mirror_copy(RIGHT) mirror_copy(BACK)
        move([case_clamping_middle_offset, case_outer_dim_xy.y/2])
            normal_case_screw()
                //this one ensures proper wall thickness for the screws in the lid, but keeps it nicely short on the outside
                if(upper && positive) up(gasket_thickness)
                    pie_slice(lid_internal_height, d=$tube_od, ang = 90, anchor = BOTTOM, spin = 180);
    //BACK
    move([0, case_outer_dim_xy.y/2])
        normal_case_screw()
            //this one ensures proper wall thickness for the screws in the lid, but keeps it nicely short on the outside
            if(upper && positive) up(gasket_thickness)
                pie_slice(lid_internal_height, d=$tube_od, ang = 180, anchor = BOTTOM, spin = 180);
    //The one in the cable channel
    move(cable_screw_position)
        screw_point(
            // this one takes a M3x20 screw
            struct_set(case_screw, "length", 20), case_nut, positive, negative, upper, lower, screw = screw,
            gap = gasket_thickness,
            screw_bite = 15,
            use_nut_side_trap = false,
            nut_slot_z_clearance = 3, 
            nut_slop = 0.1,
            tube_extra_length = 0,
            screw_hole_extra_length = 0,
            rounding1 = case_rounding,
            chamfer = 0
        );
}

pcb_screw = screw_info(str("M2,", 12), head = "socket", drive="hex", shaft_oversize = 0.85, head_oversize = 0.85, thread="none");
pcb_nut = nut_info("M2", shape = "hex", thickness = 1.4);
pcb_screw_hole_wall = 1.6; 


module pcb_screws(){
    //protrudes slightly in the lid on purpose, because of the angle they are at.
    total_tube_height = lid_to_display_dist - pcb_hole_z_offset + case_wall/2;
    screw_bite = 10.3;

    //Screws in order (in coordinate system of case): BACK + LEFT, FRONT + RIGHT, BACK + RIGHT, FRONT + LEFT
    z_rotations = [180, 0, 90, -90];
    outwards_tilt = -10;
    chamfer_angle = 81;
    x_rotations = [0, outwards_tilt, outwards_tilt, 0];
    screw_bites = [screw_bite, screw_bite, screw_bite, 8.5];
    chamfer_angles = [chamfer_angle, chamfer_angle, chamfer_angle, 78];

    multmatrix(pcb_transform_matrix) for(i = idx(pcb_screw_holes)){
        move(pcb_screw_holes[i]){
            down(0.2) mirror(UP) rotate(-45 + z_rotations[i]) xrot(x_rotations[i]){
                screw_point(
                    pcb_screw, pcb_nut,
                    nut_insert_wall = pcb_screw_hole_wall,
                    screw_bite = screw_bites[i],
                    tube_extra_length = total_tube_height - screw_bites[i],
                    screw_hole_extra_length = 5,
                    nut_slot_z_clearance = 1,
                    bridge_helper_width = s2_walls/2,
                    bridge_helper_height = 0.6,
                    rounding2 = 0,
                    chamfer = 0,
                    lower = true,
                    screw = true,
                    keep_tag="pcb_screw"
                ) chamfer_cylinder_mask(d = $tube_od, chamfer = 1.3, ang = chamfer_angles[i]);
            }
            tag("remove")
                cyl(2, d=6, anchor = TOP);
        }
     }
}

//the arguments for chamfer go to a cube on the bottom of the tube, so any edges which don't include BOTTOM probably include weird results
module screw_point(
    screw_info, nut_info, //screw/nut specs resulting from screw_info() and nut_info(), for the hardware you want to use
    positive = true, negative = true, //whether to generate geometry which adds (positive) and/or geometry to remove (negative) material 
    upper = false, lower = false, //whether to generate geometry above and or below the mating plate
    screw = false, //if true, render the screw
    //Parameters for chamfering the lower part, it applies to a cube, which gets intersected with the main cylinder
    chamfer = case_screw_chamfer,
    edges = [BOTTOM + BACK, BOTTOM + FRONT], except_edges = [],
    rounding1 = 0, teardrop1 = true, //parameters for rounding the bottom of the lower cylinder
    rounding2 = case_screw_rounding, teardrop2 = true, //parameters for rounding the top of the upper cylinder
    screw_bite = 9, //how many mm should the screw be into the threaded insert
    nut_insert_wall = case_wall, //wall thickness around the nut (not completely correct when shape is hex)
    nut_slot_z_clearance = 0.8, //makes the nut slot higher, for easy fit
    nut_slop = 0, //general slop for nut slots
    bridge_helper_width = s4_walls, bridge_helper_height = layer_height, //makes the first part of the hole in the lower part rectangular for easy bridging
    head_counterbore_length = 20, //length of the cutout for the screw head in the upper part
    tube_extra_length = 9,
    screw_hole_extra_length = 4,
    gap = 0, //gap between lower and upper part. reduces the size of the upper part while keeping the distance between the nut and the screw head the same.
    use_nut_side_trap = true, //decides if there is a slot in the side to insert the nut
    remove_tag = "remove",
    keep_tag = "keep"
){
    screw_hole_dia = struct_val(screw_info, "diameter") + struct_val(screw_info, "shaft_oversize");
//    $tube_od = struct_val(nut_info, "width") + 2*nut_insert_wall;
    $tube_od = struct_val(screw_info, "head_size") + struct_val(screw_info, "head_oversize") + 2*nut_insert_wall;
    upper_tube_height = struct_val(screw_info, "length") - screw_bite + struct_val(screw_info, "head_height");
    lower_height = screw_bite + tube_extra_length;
    nut_trap_height = struct_val(nut_info, "thickness") + nut_slot_z_clearance + bridge_helper_height;

    module lower_negative(){
        //bottom_half() //makes the screw holes only remove in the lower part, but hangs up preview
        down(screw_bite){
            down(screw_hole_extra_length)
                screw_hole(screw_info, length = struct_val(screw_info, "length") + screw_hole_extra_length, counterbore=head_counterbore_length, anchor=BOTTOM);

            //we have to pass the screw spec here because of a BOSL doesn't allow overriding shape with a nut spec
            down(nut_slot_z_clearance){
                if(use_nut_side_trap)
                    nut_trap_side(trap_width = $tube_od/2, spec = screw_info, thickness = nut_trap_height, shape = struct_val(nut_info, "shape"), $slop = nut_slop, anchor = BOTTOM, spin = 90);
                else
                    nut_trap_inline(nut_trap_height, spec=screw_info, shape = struct_val(nut_info, "shape"), $slop = nut_slop, anchor = BOTTOM);
            }
        }
    }

    module upper_negative(){
        //top_half() //makes the screw holes only remove in the upper part, but hangs up preview
        down(screw_bite)
            screw_hole(screw_info , counterbore=head_counterbore_length,anchor=BOTTOM);
    }

    //holds the nut
    if(positive){
        if(screw)
            %recolor("grey") down(screw_bite) screw(screw_info, anchor = BOTTOM);
        if(upper)
            tag(keep_tag) difference(){
                //cyl is used upside down, so the teardrop has an effect
                up(gap) cyl(upper_tube_height - gap, d=$tube_od, anchor = TOP, orient=DOWN, rounding1 = rounding2, teardrop = teardrop2);
                upper_negative();
            }
        //all the geometry needed to support the nut and screw hole
        if(lower) tag(keep_tag){
            intersection(){
                union(){
                    difference(){
                        cyl(lower_height, d = $tube_od, anchor = TOP, rounding1 = rounding1, teardrop = teardrop1);
                        lower_negative();
                    }
                    //Bridge helpers, makes two thin slabs to convince the slicer to do nice bridging
                    down(screw_bite - nut_trap_height + nut_slot_z_clearance - 2*nut_slop)
                        mirror_copy(BACK, offset = -screw_hole_dia/2)
                            cube([struct_val(nut_info, "width")+ 2*nut_slop, bridge_helper_width + 2*nut_slop, bridge_helper_height], anchor = TOP + BACK);
                }
                //this cube is used to get easy to define rectangular chamfers on a cylinder
                cuboid([$tube_od, $tube_od, lower_height], chamfer = chamfer, edges = edges, except_edges = except_edges, anchor = TOP);
            }
        }
    }
        
    if(negative) tag(remove_tag){
            //hole for the screw
            if(upper)
                upper_negative();
            //nut trap
            if(lower)
                lower_negative();
    }

    //any children have access to the special $variables
    children();
}

seam_lip_width = s2_walls;
//space which will be between the lip and the fitting part
seam_lip_slop = 0.5;

module screw_and_water_test(){
    size = 26;

    z_overlap = 1.5;
    lip_height = gasket_thickness;
    lip_height_with_overlap = z_overlap + gasket_thickness;

    /*module fill_small_holes(r){
        offset(r = r) offset(r = -r) children();
    }*/

    module interface_2d(){
        projection(cut = true) down(eps) top_part();
    }

    module lip_3d(){
        module seam_lip(width, slop = 0){
            difference(){
                offset(r = width + slop) children();
                offset(r = slop) fill() children();
            }
        }

        //the part of the lip that sticks out
        down(lip_height)
            linear_extrude(height=lip_height)
                seam_lip(seam_lip_width, seam_lip_slop)
                    children();
        //the part of the lip that is next to the original part
        linear_extrude(height=z_overlap)
                seam_lip(seam_lip_width + seam_lip_slop)
                    children();
        //generate a chamfer
        up(z_overlap) linear_extrude(2.5, scale = 0.85) seam_lip(seam_lip_width, seam_lip_slop) children();
    }

    module mold_part(){
        module mold_2d(){
            difference() {
                rect(size - 2*case_wall);
                interface_2d();
            }
        }
        
        linear_extrude(lip_height) mold_2d();
        up(lip_height) bottom_half(z = 3*layer_height) roof() mold_2d();
    }

    ydistribute(spacing = size + 5){
        part("tests/water_and_screw_PETG.stl") xdistribute(spacing = size + 5){
            bottom_half() cuby();
            down(gasket_thickness) //just to align it for printing
                xrot(180){
                    lip_3d()
                        interface_2d();
                    top_part();
                }
        }

        part("tests/water_and_screw_mold_PETG.stl") mold_part();

        part("tests/water_and_screw_TPU.stl") bottom_half() down(gasket_thickness) top_half() cuby();
    }

    module top_part(){
        top_half() down(gasket_thickness) cuby();
    }

    module cuby(){
        diff() rect_tube(size - 2* case_wall, size = [size, size], wall = case_wall, rounding = case_rounding, anchor = CENTER){
            mirror_copy(BACK, offset=$parent_size.y/2) screw_point(case_screw, case_nut, tube_extra_length = 4, screw_hole_extra_length = 2, lower = true, upper = true, screw = false, edges = BOTTOM + BACK)
                //ensure wall thickness
                up(gasket_thickness)
                    pie_slice(size/2 - case_wall - gasket_thickness, d=$tube_od, ang = 180, anchor = BOTTOM, spin = 180);
            attach([TOP, BOTTOM], TOP) cuboid([size, size, case_wall], rounding = case_rounding, teardrop = true, edges = ["Z", BOTTOM]);
        }
    }
}

module closed_rect_tube(h, size, wall, anchor = CENTER, spin = 0, orient = UP){
    attachable(anchor, spin, orient, size = concat(size, h)){
        union(){
            position(TOP)
                rect_tube(h - wall, size, wall = wall, rounding = case_wall, anchor = TOP);
            position(BOTTOM)
                cuboid(concat(size, wall), rounding = case_rounding, edges = [BOTTOM, "Z"], teardrop = true, anchor = BOTTOM);
        }
        children();
    }
}

module lid(anchor = BOTTOM, spin=0, orient=UP) part("lid.stl") recolor("SlateBlue"){
    anchors = [
        named_anchor("LID_INTERNAL", [0, 0, 0])
    ];

    attachable(anchor, spin, orient, size = concat(case_outer_dim_xy, lid_internal_height + case_wall)){
        diff(){
            position(BOTTOM)
                closed_rect_tube($parent_size.z , [$parent_size.x, $parent_size.y], wall = case_wall, anchor = TOP, orient = DOWN);
            position(BOTTOM) down(gasket_thickness){
                //generates geometry to add and remove to attach case and lid together with screws
                case_clamping_screws(upper = true); //TODO make the cylinder shorter, so that it doesn't stick out, but correct it in the module, not extra differencing
                
                //adding all parts in the lid connected with the pcb
                pcb_screws(); //TODO optimize adds 300 objects to the tree
                pcb_display_window();
                pcb_button_holes();
                pcb_dev_board_pushers();
                lid_seal();
                *multmatrix(pcb_transform_matrix) move(pcb_usb_position) rotate(-90)
                    usb_c_covered_hole(anchor = BACK);
                //this on adds and removes all parts needed for the cable channel
                position(FRONT) back(case_wall){
                    render() difference(){
                        case_buldge(); //TODO: make sure it meets nicely with the case part, now it's offset from the previous printed gasket in between
                                       //the projection of case and lid should be the same where they meet (disregarding the yet to come lip)
                                       //just moving it up would solve the meeting face, but make it unnecessarily higher. complication making the internal lid for the big lid
                        //cutting away the bottom part
                        back(eps) up(gasket_thickness) cuboid([80, case_buldge_outer_dia, 40], anchor = TOP + BACK);
                    }
                    move([0, eps, -eps]) case_buldge(diff = true);
                }
            }
        }
        children();
    }
}

module gasket(anchor = BOTTOM, spin=0, orient=UP) part("gasket.stl") recolor("white"){
    attachable(anchor, spin, orient, size = concat(case_outer_dim_xy, gasket_thickness)){
        union(){
            //the gasket should have the same shape as the BOTTOM of the lid, so we just take the shape from there
            position(BOTTOM)
                linear_extrude(gasket_thickness) projection(cut=true) down(eps)
                    lid();
            //add a small feature to connect the isle of gasket for the cable channel to the rest
            move(cable_screw_position)
                rotate(-50) right(case_wall )
                    cube([10, case_wall, gasket_thickness], anchor = LEFT);
        }
        children();
    }
}

module case(anchor = TOP, spin=0, orient=UP) part("case.stl") recolor("FireBrick"){
    attachable(anchor, spin, orient, size = concat(case_outer_dim_xy, case_inner_dim_z + case_wall)){
        diff(){
            closed_rect_tube($parent_size.z, [$parent_size.x, $parent_size.y], case_wall);
            position(TOP){
                //generates geometry to add and remove to attach case and lid together with screws
                case_clamping_screws(lower = true);
                
                //stoppers for the cell_holders 
                stopper_width = loadcell_cutout_width - 2*cell_to_case_gap_xy - case_cell_holder_stoppers_gap*2;
                tag("keep") zrot_copies(n = 2) position(RIGHT + FRONT) move([-case_wall - cell_to_case_gap_xy - loadcell_cutout_to_edge - loadcell_cutout_width/2, case_wall])
                    //the chamfer makes inserting the loadcell in the case easier, even if you only do it once, chamfers cost nothing ¯\_(ツ)_/¯
                    cuboid([stopper_width, cell_holder_width , case_inner_dim_z], chamfer = stopper_width/2, edges = [TOP + LEFT, TOP + RIGHT], anchor = FRONT + TOP);
                
                //this on adds and removes all parts needed for the cable channel
                position(FRONT) back(case_wall){
                    render() difference(){
                        case_buldge();
                        //cutting away the top part
                        back(eps) cuboid([80, case_buldge_outer_dia, 15], anchor = BOTTOM + BACK);
                    }
                    move([0, eps, eps]) case_buldge(diff = true);
                }

                //holes for the letting the loadcell nuts exit the case
                //will be sealed with hot glue
                tag("remove") mirror_copy(RIGHT) position(LEFT)
                    move([-eps, 0, eps]) cube([case_wall + 2*eps, case_nut_cutout_width_dia, case_inner_dim_z/2], anchor = LEFT + TOP)
                        position(BOTTOM)
                            cyl($parent_size.x, d=case_nut_cutout_width_dia, orient = LEFT);
            }
        }
        children();
    }
}

case_buldge_gap = 1.75;
case_buldge_height = loadcell_cable_dia + 2*case_wall + cell_to_case_gap_z;//loadcell_cable_nut_width + 12 + 2*case_wall;
case_bulge_z_offset = 1.5;
case_buldge_outer_dia = loadcell_cable_bend + loadcell_cable_nut_width/2 + 2*case_wall + 2*case_buldge_gap;
case_buldge_straight_length = 5;

straight_cable_channel_dim = [case_buldge_outer_dia, case_buldge_straight_length, case_buldge_height/2];

//has to be positioned at FRONT + TOP of case
//this takes the cable of the load cell as reference and creates a channel for it
module case_buldge(diff = false){
    force_tag(diff ? "remove" : "buldge") enlarge(gasket_thickness, direction = UP, symmetric = false)
    minkowski(){
        hull()
            front_half() back(cell_to_case_gap_xy){
                //By splitting up the loadcell_cable in top and bottom, the same overall dimension can be kept,
                //while creating a straight part for the gasket.
                bottom_half() down(cell_to_case_gap_z) 
                    loadcell_cable();
                down(gasket_thickness) top_half(z=gasket_thickness) down(cell_to_case_gap_z) 
                    loadcell_cable();
                //this cylinder expands the one side, through the hull to create a better interface between case, lid and gasket
                right(loadcell_cable_nut_width/2)
                    cyl(2*case_wall, d= case_wall, anchor = BOTTOM + RIGHT, orient = FRONT);
            }
        //for the part that is diffed away later, the minkowski is made with a smaller sphere
        front_half() sphere(r=(diff ? 0 : case_wall) + case_buldge_gap);
    }
}

case_nut_cutout_width_dia = 29;

case_outer_dim = concat(case_outer_dim_xy, case_wall + case_inner_dim_z + gasket_thickness + lid_internal_height + case_wall);