/*
    Author: Moritz Hollich
    
    Overview:
    The script contains a primary module: `enlarge`. 
    The purpose of this module is to expand any cross section of a 3D models

    Usage:
    To use this module, you need to include the script in your OpenSCAD project and 
    call the module with appropriate parameters.

    Example Usage:
    include <path_to_this_script.scad>;

    enlarge(add_dist=5, cut_offset=2, rotation=[45,0,0], rot_reverse=true, direction=UP, symmetric=false, mirror=true, object_size=50, debug=true) {
        // Your geometry here
        sphere(10);
    }
*/

include <BOSL2/std.scad>

//tests
*enlarge(-4, cut_offset = 6, direction=UP, symmetric = false, mirror=true, debug = false, object_size = 300)
    down(15) test();

*enlarge(5, cut_offset = 3, direction=LEFT + BACK + DOWN, symmetric = true, mirror=true, debug = true, object_size = 300)
test();

module test(){
    cyl(30, d2 = 10, d1 = 20, anchor = BOTTOM);
    cube([10, 10, 30], anchor = BOTTOM + LEFT);
}



/**
 * Module to enlarge a child object with various parameters for customization.
 * 
 * Attention: if the result seems weird, increase object_size to cut away all necessary parts
 * 
 * @param add_dist (numeric) The distance by which to enlarge the child object.
 * @param cut_offset (numeric, default: 0) The vertical offset applied to the child object.
 * @param rotation (vector, default: [0,0,0]) The rotation angles to apply to the child object.
 * @param rot_reverse (boolean, default: false) If true, reverses the direction and order of the rotation.
 * @param direction (constant, default: UP) The direction of the enlargement.
 * @param symmetric (boolean, default: true) If true, the enlargement is symmetric.
 * @param mirror (boolean, default: false) If true, it executes enlarge twice and changes the direction and cut_offset in between.
 * @param object_size (numeric, default: 100) The size of the cutter used to enlarge the object.
 * @param debug (boolean, default: false) If true, enables debugging visualization.
 */
module enlarge(add_dist, cut_offset = 0, rotation = [0,0,0], rot_reverse = false, direction = UP, symmetric = true, mirror = false, object_size= 100, debug = false){
    module cut_and_move(dir = DOWN){
        move(dir*add_dist/2)
            difference(){
                move_child() children();
                cube(object_size, anchor = BOTTOM, orient=-dir);
            }
    }

    module move_child(reverse = false){
        if(reverse){
            rot(from=direction, to=UP, reverse=true) rot(rotation, reverse = !rot_reverse) up(cut_offset)  
                children();
        }else{
            down(cut_offset) rot(rotation, reverse = rot_reverse) rot(from=direction, to=UP)
                children();
        }
    }

    module optional_debug(){
        if(debug)
            #children();
        else
            children();
    }
    
    if(mirror){
        // Handle mirroring by calling enlarge twice with opposite cut_offset and direction
        enlarge(add_dist, cut_offset, rotation, rot_reverse, direction, symmetric, false, object_size, debug)
            enlarge(add_dist, cut_offset, rotation, rot_reverse, -direction, symmetric, false, object_size, debug)
                children();
    }else if(add_dist >=0){
        //undo's the move_child transformation
        //rot(from=UP, to=direction, reverse=true)
        //rot(rotation, reverse=!rot_reverse)
        //move(direction * cut_offset){
        move_child(reverse=true)
        up(symmetric ? 0 : add_dist/2){
            // If symmetric, it pushes both halves away from the cut_offset
            // in the unsymmetric case, this will be the side that stay in the same place, and only gets cut
            cut_and_move(dir=DOWN) children();
            optional_debug() linear_extrude(add_dist, center=true)
                projection(cut=true)
                    move_child() children();
            cut_and_move(dir=UP) children();
        }
    } else{
        move_child(reverse=true){
            up(add_dist/2) cut_and_move(dir=DOWN) move(symmetric ? -direction * add_dist/2 : [0, 0, 0])
                children();
            down(add_dist/2) cut_and_move(dir=UP) move(symmetric ? direction * add_dist/2 : direction * add_dist)
                children();
        }
    }
}