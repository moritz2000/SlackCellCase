include <BOSL2/std.scad>
include <BOSL2/screws.scad>

include <partsScad/partsScad.scad>

include <loadCell.scad>
include <pcb.scad>
include <battery.scad>


$fa = $preview ? 10 : 1;
$fs = $preview ? 1 : 0.25;

//used for some BOSL stuf, for example nut traps
$slop = 0.3;

//ignore message about changes in BOSL api
$align_msg = false;

cell_to_case_gap_xy = 3.5;
cell_to_case_gap_z = 2;

layer_height = 0.2; //TODO
s2_walls = 1.14;
s4_walls = 2.21;
s6_walls = 3.28;

case_wall = s6_walls;
case_rounding = case_wall;
//TODO Teardrop rounding

case_inner_dim_xy = [s_beam_dim.x, s_beam_dim.y] + repeat(2*cell_to_case_gap_xy, 2);
case_inner_dim_z = s_beam_dim.z + 2*cell_to_case_gap_z;

case_outer_dim_xy = case_inner_dim_xy + repeat(2*case_wall, 2);

cell_holder_width = 10;

cell_holder_rounding = case_rounding - case_wall;

render_spacing = 100;
show_only_left_half = false;//$preview;
show_only_front_half = $preview;

screw_and_water_test();


//when rendering explode the parts sideways up to be able to differentiate them. Export is done through partsScad
*xdistribute(spacing = $preview ? 0 : render_spacing){
    case(anchor = TOP)
        %position(TOP) down(cell_to_case_gap_z + s_beam_dim.z/2) load_cell(show_s_beam = false);
    


    *cell_holders(anchor = TOP);

    gasket(anchor = BOTTOM);

    *up(gasket_thickness)
        lid(anchor = BOTTOM);

    //TODO, Take into account gasket thickness and lid in position
    *%up(lid_internal_height) pcb(spin = 90, anchor = TOP)
        attach(BOTTOM, TOP)
            %fwd(10) battery(spin = -90);
    
    %up(eps) case_clamping_screws(lower = false, upper = false, screw = true);

}



//cell_holders_print();

module cell_holders_print(){
    mirror_copy(v=LEFT, offset = -cell_holder_width - 0.3)
    mirror_copy(v=FRONT, offset = -cell_holder_width - 0.3)
        cell_holder();
    
    //bridging helper
    up(s_beam_dim.z/2) cuboid( [cell_holder_width*2, cell_holder_width*2, 2*layer_height],
            rounding = cell_holder_rounding, edges = "Z",
            anchor = BOTTOM);

    tube(s_beam_dim.z, od = 10, wall = s2_walls);
}

//corner piece which allows the loadcell to move while being inside the housing
module cell_holders(anchor = CENTER, spin = 0, orient = UP) {
    /*attachable(anchor, spin, orient, size = concat(case_inner_dim_xy, [case_inner_dim_z])){
        union(){
            mirror_copy(v=RIGHT, offset = case_inner_dim_xy.x/2)
            mirror_copy(v=BACK, offset = case_inner_dim_xy.y/2)
                cell_holder();
        }
        children();
    }*/
    attachable(anchor, spin, orient, size = [case_inner_dim_xy.x - 2*cutout_to_edge - 2*cutout_width, case_inner_dim_xy.y, case_inner_dim_z]){
        zrot_copies(n=2){
            move([s_beam_dim.x/2 - cutout_width - cutout_to_edge, -s_beam_dim.y/2] + [cell_to_case_gap_xy, -cell_to_case_gap_xy]) rotate(-90) cell_holder();
        }
        children();
    }
}

module cell_holder() part("cell_holder.stl") recolor("white"){
    difference(){
            cuboid( [cell_holder_width, cell_holder_width , case_inner_dim_z],
                    rounding = cell_holder_rounding, edges = BACK + RIGHT,
                    anchor = RIGHT + BACK);
        translate([-case_inner_dim_xy.x/2, -case_inner_dim_xy.y/2])
            load_cell(screw_ons=false);
    }
}

gasket_thickness = 0.95; //TODO



//is attachable
module case_tube(height = case_inner_dim_z, anchor = CENTER, spin=0, orient=UP){
    rect_tube(  height,
                isize = case_inner_dim_xy,
                wall = case_wall, rounding = case_rounding, anchor = anchor, spin=spin, orient=orient){
                    children();
                }
}

//For M3 threaded insert
threaded_insert_wall = case_wall; //TODO test
threaded_insert_dia = 4.5; //TODO test

screw_bite = 4; //how many mm should the screw be into the threaded insert
threaded_insert_length = 5.5;

case_clamping_middle_offset = case_outer_dim_xy.x/2 - 7;

case_screw = screw_info(str("M3,", 12), head = "socket", drive="hex", shaft_oversize = 0.8, head_oversize = 0.8, thread="none");

case_screw_counterbore = 20; //doesn't hurt to be larger than needed


screw_chamfer_length = 5;

//this moves one of the screw holes to be not in the way of the cable of the load cell
cable_screw_offset = -13;

//this includes needed support and cut aways for a screw attachment
//at the height of the anchor point is the change between screw hole (above) and threaded insert (below)
module case_clamping_screws(positive = true, negative = true, upper = false, lower = false, screw = false){
    //All corners
    mirror_copy(RIGHT) mirror_copy(BACK)
        move([case_clamping_middle_offset, case_outer_dim_xy.y/2]) screw_point(case_screw, positive, negative, upper, lower, screw = screw);
    //BACK
    move([0, case_outer_dim_xy.y/2]) screw_point(case_screw, positive, negative, upper, lower, screw = screw);
    //The one in the cable channel
    move([cable_screw_offset, -case_outer_dim_xy.y/2 - 10]) screw_point(case_screw, positive, negative, upper, lower, screw = screw, chamfer = 3, edges = BOTTOM + LEFT);
}

//TODO correct the anchors, not urgent
//the arguments for chamfer go to a cube on the bottom of the tube, so any edges which don't include BOTTOM probably include weird results
module screw_point(screw_info, positive = true, negative = true, upper = false, lower = false, screw = false, remove_tag = "remove", chamfer = screw_chamfer_length, edges = [BOTTOM + BACK, BOTTOM + FRONT], except_edges = [], rounding2 = case_rounding, teardrop = true){
    tube_od = threaded_insert_dia + 2*threaded_insert_wall;
    upper_tube_height = struct_val(screw_info, "length") - screw_bite + struct_val(screw_info, "head_height");
    //holds the inserts
    if(positive){
        if(screw)
            %recolor("grey") down(screw_bite) screw(screw_info, anchor = BOTTOM);
        if(upper)
            tag("keep") difference(){
                //cyl is used upside down, so the teardrop has an effect
                cyl(upper_tube_height, d=tube_od, anchor = TOP, orient=DOWN, rounding1 = rounding2, teardrop = teardrop);
                down(screw_bite)
                    screw_hole(screw_info , counterbore=case_screw_counterbore,anchor=BOTTOM);
            }
        //threaded insert stuff below
        if(lower) tag_diff("keep") tube(threaded_insert_length, id = threaded_insert_dia, wall = threaded_insert_wall, anchor = TOP)
            position(BOTTOM)
                //flat chamfer for a easy printing and strength
                intersection(){
                    cyl(screw_chamfer_length, d=$parent_size.x, anchor = TOP);
                    cuboid([$parent_size.x, $parent_size.y, screw_chamfer_length], chamfer = chamfer, edges = edges, except_edges = except_edges, anchor = TOP);
                }
    }
        
    if(negative) tag("remove"){
            //hole for the screw
            if(upper) down(screw_bite)
                screw_hole(screw_info , counterbore=case_screw_counterbore,anchor=BOTTOM);
            //hole for the threaded insert
            if(lower) cyl(threaded_insert_length, d = threaded_insert_dia, anchor = TOP);
    }
}

module screw_and_water_test(){
    size = 26;

    ydistribute(spacing = size + 5){
        part("tests/water_and_screw_PETG.stl") xdistribute(spacing = size + 5){
            bottom_half() cuby();
            down(gasket_thickness) //just to align it for printing
                xrot(180) top_half() down(gasket_thickness) cuby();
        }

        part("tests/water_and_screw_TPU.stl") bottom_half() down(gasket_thickness) top_half() cuby();
    }

    module cuby(){
        diff() rect_tube(size - 2* case_wall, size = [size, size], wall = case_wall, rounding = case_rounding, anchor = CENTER){
            mirror_copy(BACK, offset=$parent_size.y/2) screw_point(case_screw, lower = true, upper = true, screw = false);
            attach([TOP, BOTTOM], TOP) cuboid([size, size, case_wall], rounding = case_rounding, teardrop = true, edges = ["Z", BOTTOM]);
        }
    }
}


lid_internal_height = 15; //TODO derive from the space, the electronics take up


module lid(anchor = BOTTOM, spin=0, orient=UP) part("lid.stl") recolor("SlateBlue") render() maybe_left_half() maybe_front_half(){
    anchors = [
        named_anchor("LID_INTERNAL", [0, 0, 0])
    ];

    attachable(anchor, spin, orient, size = concat(case_outer_dim_xy, lid_internal_height + case_wall)){
        union(){
            position(BOTTOM) top_half(s=200)
                case_all(anchor = "TOP_HALF_BOTTOM");
            
        }
        children();
    }
}

module gasket(anchor = BOTTOM, spin=0, orient=UP) part("gasket.stl") recolor("white") render() maybe_left_half() maybe_front_half(){
    attachable(anchor, spin, orient, size = concat(case_outer_dim_xy, gasket_thickness)){
        position(BOTTOM) bottom_half(z = gasket_thickness, s = 200) top_half(s=200)
            case_all(anchor = "BASE_TOP");
        children();
    }
}

module case(anchor = TOP, spin=0, orient=UP) part("case.stl") recolor("FireBrick") render() maybe_left_half() maybe_front_half(){
    attachable(anchor, spin, orient, size = concat(case_outer_dim_xy, case_inner_dim_z + case_wall)){
        position(TOP) bottom_half(s = 200) case_all(anchor = "BASE_TOP");
        children();
    }
}

case_buldge_height = cable_dia + 2*case_wall + cell_to_case_gap_z;//load_cell_cable_nut_width + 12 + 2*case_wall;
case_bulge_z_offset = 1.5;
case_buldge_outer_dia = cable_bend + load_cell_cable_nut_width/2 + case_wall * 2 + cell_to_case_gap_xy;
case_buldge_straight_length = 5;

straight_cable_channel_dim = [case_buldge_outer_dia, case_buldge_straight_length, case_buldge_height/2];

//has to be positionend at FRONT + TOP of case
//this takes the cable of the load cell as reference and creates a channel for it
module case_buldge(diff = false){
    minkowski(){
        hull()
            front_half() back(cell_to_case_gap_xy){
                down(cell_to_case_gap_z) 
                    load_cell_cable();
                //this cylinder expands the one side, through the hull to create a better iterface between case, lid and gasket
                up(gasket_thickness) right(load_cell_cable_nut_width/2)
                    cyl(2*case_wall, d= case_wall, anchor = BOTTOM + RIGHT, orient = FRONT);
            }
        //for the part that is diffed away later, the minkowski is made with a smaller sphere
        front_half() sphere(r=(diff ? 0 : case_wall) + cell_to_case_gap_xy/2);
    }
}

case_nut_cutout_width_dia = 29;

case_outer_dim = concat(case_outer_dim_xy, case_wall + case_inner_dim_z + gasket_thickness + lid_internal_height + case_wall);

module case_all(anchor = CENTER, spin = 0, orient = UP){
    base_top_z = -case_outer_dim.z/2 + case_wall + case_inner_dim_z;

    anchors = [
        named_anchor("BASE_TOP", [0, 0, base_top_z]),
        named_anchor("TOP_HALF_BOTTOM", [0, 0, base_top_z + gasket_thickness])
    ];

    attachable(anchor, spin, orient, size = case_outer_dim, anchors = anchors){
        diff() cuboid(case_outer_dim, rounding = case_rounding, edges = "Z"){
            //big void in the middle
            tag("remove")
                cuboid($parent_size - repeat(2*case_wall, 3));
            //take the plane between bottom part and gasket as reference
            up(base_top_z){
                //stoppers for the cell_holders
                tag("keep") zrot_copies(n = 2) position(RIGHT + FRONT) move([-case_wall - cutout_to_edge - cutout_width, case_wall])
                    cuboid([case_wall, cell_holder_width , case_inner_dim_z], anchor = LEFT + FRONT + TOP);
                case_clamping_screws(lower = true, upper = true);
                //this on adds and removes //TODO buggy
                position(FRONT) back(case_wall){
                    case_buldge();
                    tag("remove") case_buldge(diff = true);
                }
                //holes for the letting the nuts exit the case
                //will be sealed with hot glue
                tag("remove") mirror_copy(RIGHT) position(LEFT)
                    cube([case_wall, case_nut_cutout_width_dia, case_inner_dim_z/2], anchor = LEFT + TOP)
                        position(BOTTOM)
                            cyl(case_wall, d=case_nut_cutout_width_dia, orient = LEFT);
            }
            //doing the teardrop manual to be able to do top and bottom
            edge_mask([TOP, BOTTOM])
                teardrop_edge_mask(max($parent_size) + 1, r = case_rounding);
            corner_mask([TOP, BOTTOM])
                teardrop_corner_mask(r = case_rounding);
        }
        children();
    }
}

module maybe_front_half(){
    if(show_only_front_half)
        front_half()
            children();
    else
        children();
}

module maybe_left_half(){
    if(show_only_left_half)
        left_half()
            children();
    else
        children();
}