include <BOSL2/std.scad>
include <BOSL2/screws.scad>

include <partsScad/partsScad.scad>

include <loadCell.scad>
include <pcb.scad>
include <battery.scad>


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

ydistribute(spacing = 80){
    screw_and_water_test();
    //when rendering explode the parts sideways up to be able to differentiate them. Export is done through partsScad
    xdistribute(spacing = $preview ? 0 : 100){
        case(anchor = TOP){
            %load_cell();
        }
        //TODO, Take into account gasket thickness and lid in position
        *%right(10) battery(anchor = BOTTOM);
        *%up(6) pcb(spin = 90, anchor = BOTTOM);

        cell_holders(anchor = TOP);

        !gasket(anchor = BOTTOM);
        up(gasket_thickness) lid(anchor = BOTTOM);
    }
    cell_holder();
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

module cell_holder() part("cell_holder.stl") color("white", alpha=0.6){
    difference(){
            cuboid( [cell_holder_width, cell_holder_width , case_inner_dim_z],
                    rounding = cell_holder_rounding, edges = BACK + RIGHT,
                    anchor = RIGHT + BACK);
        translate([-case_inner_dim_xy.x/2, -case_inner_dim_xy.y/2])
            load_cell(screw_ons=false);
    }
}

gasket_thickness = 0.95; //TODO

module gasket(anchor = CENTER, spin=0, orient=UP) part("gasket.stl") color("white", alpha=0.6){
    tag_diff("gasket") case_tube(gasket_thickness, anchor=anchor, spin=spin, orient=orient){
        //change shape of gasket according to screw attachment and case buldge
        position(BOTTOM) case_clamping_screws(upper = true);
        position(BOTTOM + FRONT)case_buldge();
        tag("remove") position(TOP)
            cube([200, 200, 30], anchor = BOTTOM);
        tag("remove") position(BOTTOM)
           cube([200, 200, 30], anchor = TOP);
        children();
    }
}

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
threaded_insert_dia = 4; //TODO test
threaded_insert_length = 5.5;
screw_bite = 4; //how many mm should the screw be into the threaded insert
screw_point_outer_dia = threaded_insert_dia + 2*threaded_insert_wall;
threaded_insert_outset = screw_point_outer_dia - case_wall - cell_to_case_gap_xy/2;

case_clamping_middle_offset = case_outer_dim_xy.x/3;

//TODO use the following in the screw hole and validate all of these with a test print, same for head size
case_screw_hole_dia = 3.5; //TODO make it somehow different for TPU and PETG?

case_screw_length = 12; //TODO look if it fits for a higher case and look inside of the case for water tightness!
case_screw = screw_info(str("M3,", case_screw_length), head = "socket", drive="hex");
case_screw_counterbore = 5; //TODO



screw_chamfer_length = 5;
//this includes needed support and cut aways for a screw attachment
//at the height of the anchor point is the change between screw hole (above) and threaded insert (below)

module case_clamping_screws(positive = true, negative = true, upper = false, lower = false, screw = false){
    //align(anchor, [BACK, FRONT], inset = -threaded_insert_outset , overlap = threaded_insert_length)
    mirror_copy(BACK, offset = case_outer_dim_xy.y/2)
        mirror_copy(RIGHT, offset = case_clamping_middle_offset)
            screw_point(positive, negative, upper, lower, screw = screw, anchor = TOP);
}

//NOTE correct the anchors, not urgent
module screw_point(positive = true, negative = true, upper = false, lower = false, screw = false, remove_tag = "remove", anchor = TOP, spin = 0, orient = UP){
    //holds the inserts
    if(positive)
        attachable(anchor, spin, orient, l=threaded_insert_length, d = screw_point_outer_dia){
            union(){
                if(screw)
                    %attach(TOP, BOTTOM) down(screw_bite) screw(case_screw);
                if(upper) position(TOP)
                    tube(case_screw_length - screw_bite + struct_val(case_screw, "head_height"), id=case_screw_hole_dia, od = screw_point_outer_dia, anchor = BOTTOM);
                //threaded insert stuff below
                if(lower) tube(threaded_insert_length, id = threaded_insert_dia, wall = threaded_insert_wall)
                    attach(BOTTOM, TOP)
                        //flat chamfer for a easy printing and strength
                        tag_diff("screw_attachment") cyl(screw_chamfer_length, d=$parent_size.x)
                            mirror_copy(BACK) position(TOP + FRONT) tag("remove")
                                wedge([$parent_size.x, $parent_size.y/2, screw_chamfer_length + eps], anchor = TOP + FRONT);
            }
            children();
        }
        

    if(negative) tag("remove")
    attachable(anchor, spin, orient, l=threaded_insert_length, d = threaded_insert_dia + 2*threaded_insert_wall){
        union(){
            //hole for the screw
            if(upper) attach(TOP, BOTTOM) down(screw_bite)
                screw_hole(case_screw , counterbore=case_screw_counterbore,anchor=TOP);//cyl(case_screw_length, d= case_screw_hole_dia);
            //hole for the threaded insert
            if(lower) cyl(threaded_insert_length, d = threaded_insert_dia);
        }
        children();
    }
}

module screw_and_water_test(){
    size = 26;

    ydistribute(spacing = size + 5){
        part("tests/water_and_screw_PETG.stl") xdistribute(spacing = size + 5){
            bottom_half() cuby();
            xrot(180) down(gasket_thickness) top_half() cuby();
        }

        part("tests/water_and_screw_TPU.stl") bottom_half() down(gasket_thickness) top_half() cuby();
    }



    module cuby(){
        diff() rect_tube(size - 2* case_wall, size = [size, size], wall = case_wall, rounding = case_rounding, anchor = CENTER){
            mirror_copy(BACK, offset=$parent_size.y/2) screw_point(lower = true, upper = true, screw = true);
            attach([TOP, BOTTOM], BOTTOM) cuboid([size, size, case_wall], rounding = case_rounding, edges = ["Z", UP]);
        }
    }
}


lid_internal_height = 10; //TODO derive from the space, the electronics take up


module lid(anchor = CENTER, spin=0, orient=UP) part("lid.stl"){
    tag_diff("lid") case_tube(lid_internal_height, anchor = anchor, spin = spin, orient = orient){
        attach(TOP,TOP)
            plane_lid();
        position(BOTTOM) //TODO somehow take into account that there is the gasket in between
            case_clamping_screws(upper = true, screw = true);
        children();
    }
}

case_buldge_height = load_cell_cable_nut_width + 2 + 2*case_wall;

module case_buldge(){
    yrot(-load_cell_cable_angle)
        back(case_wall) right(load_cell_cable_nut_width) front_half()
            down(case_buldge_height/2) mirror_copy(UP)//needed to get teardrop rounding on both sides
                cyl(case_buldge_height/2,  d = cable_bend + load_cell_cable_nut_width/2 + case_wall * 2, anchor = RIGHT + TOP, rounding1 = case_rounding, teardrop = true)
                    tag("remove") position(TOP)
                        cyl(case_buldge_height - 2*case_wall, d= $parent_size.x - 2*case_wall);
}

case_nut_cutout_width_dia = 29;

module case(anchor = CENTER, spin=0, orient=UP) part("case.stl"){
    diff() case_tube(anchor=anchor, spin=spin, orient=orient){
        attach(BOTTOM, TOP) plane_lid();
        position(TOP)
            case_clamping_screws(lower = true);
        //stoppers for the cell_holders
        zrot_copies(n = 2) position(RIGHT + FRONT) move([-case_wall - cutout_to_edge - cutout_width, case_wall])
            cuboid([case_wall, cell_holder_width , case_inner_dim_z], anchor = LEFT + FRONT);
        position(FRONT + TOP)
            bottom_half() case_buldge();
        //holes for the letting the nuts exit the case
        //will be sealed with hot glue
        align(LEFT, TOP, inside = true)
            cube([case_wall, case_nut_cutout_width_dia, case_inner_dim_z/2])
                position(BOTTOM)
                    cyl(case_wall, d=case_nut_cutout_width_dia, orient = LEFT);
        children();
    }
}

//top or bottom plate with teardrop rounding
module plane_lid(anchor = CENTER, spin = 0, orient = TOP){
    cuboid([$parent_size.x, $parent_size.y, case_wall], teardrop = true, rounding=case_rounding, edges = ["Z", DOWN], anchor = anchor, spin = spin, orient = orient)
        children();
}