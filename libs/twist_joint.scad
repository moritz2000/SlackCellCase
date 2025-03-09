include <BOSL2/std.scad>

//Usage:
//$slop = 1; //made bigger two visualize here, should be smaller in your design
//example_config = twist_joint_config(20, 15, 5, 4);

*diff() cylinder(20, d=40){ //part where you want to have the internal joint
    attach(BOTTOM, "flush")
    twist_joint(example_config, internal=true)
        tag("keep") attach("joint", "joint")
            color("green") twist_joint(example_config)
                attach(BOTTOM, TOP)
                    cube(10); //thing you want to join
    tag("remove")
        cube(45, anchor = BACK + RIGHT);
}


//dia: diameter of the bulk of the connector, the lip sticks out
//height: total height of the joint
//lip_height: height of the lip that is used to interlock the two pieces
//lip_extend: how much the lip sticks out
//extra_angle_... : helps with insertion
function twist_joint_config(dia, height, lip_height, lip_extend, extra_angle=5, extra_angle_internal=5, rotate=0, num_lips = 2) = [dia, height, lip_height, lip_extend, extra_angle, extra_angle_internal, rotate, num_lips];

//generate a config with twist_joint_config and reuse it for part and the mask
module twist_joint(config, internal = false, excess = 0.1, anchor, spin, orient){
    //taken from https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Other_Language_Features#$fn
    function get_fn(r) = ($fn>0?($fn>=3?$fn:3):ceil(max(min(360/$fa,r*2*PI/$fs),5)));

    dia = config[0];
    height = config[1];
    lip_height = config[2];
    lip_extend = config[3];
    extra_angle = config[4];
    extra_angle_internal = config[5];
    rotate = config[6];
    num_lips = config[7];

    lip_dia = dia + 2*lip_extend;
    lip_dia_internal = lip_dia + 2*get_slop();

    internal_anchors = [
        named_anchor("joint", [0, 0, height/2-get_slop()], DOWN, 0),
        named_anchor("flush", [0, 0, -height/2], UP, 0)
    ];

    external_height = height - get_slop();

    external_anchors = [
        named_anchor("joint", [0, 0, external_height/2], TOP, 0)
    ];

    internal_dia = dia + 2*get_slop();

    lip_angle_full = 180/num_lips;

    if(internal){
        tag("remove") attachable(anchor, spin, orient, d=internal_dia, l=height, anchors=internal_anchors){
            rotate(rotate) down(excess/2) cylinder(height + excess, d = dia + 2*get_slop(), anchor=CENTER){
                zrot_copies(n = num_lips) position(TOP){
                    pie_slice(height + excess, d=lip_dia_internal, anchor=TOP, ang=lip_angle_full);
                    //This pie slice generates an awful number of calculations and makes the preview slow
                    //zrot(lip_angle_full) pie_slice(lip_height + 2*get_slop(), d2=lip_dia_internal, d1 = 1, anchor=TOP, ang=lip_angle_full - extra_angle_internal);
                    //for some reason, probably because it's 2d first, this is way faster
                    slice_height = lip_height + 2*get_slop();
                    r=lip_dia_internal/2;
                    down(slice_height) linear_extrude(slice_height) ring(d2= lip_dia_internal, d1 = 1, angle=[lip_angle_full, 2*lip_angle_full - extra_angle_internal], n=get_fn(lip_dia_internal/2));
                }
            }
            children();
        }
    }else{
        attachable(anchor, spin, orient, d=dia, l=external_height, anchors = external_anchors){
            rotate(rotate) cylinder(external_height, d = dia, anchor=CENTER)
                zrot_copies(n = num_lips) position(TOP)
                    diff("remove_twist"){
                        pie_slice(lip_height, d=lip_dia, anchor=TOP, ang=lip_angle_full - extra_angle)
                            //add chamfers to the lips, so it's easier to twist together
                            zrot_copies([0, lip_angle_full - extra_angle]) position(CENTER) tag("remove_twist")
                                zcopies(spacing=lip_height, n = 2)
                                    chamfer_edge_mask(l=lip_dia/2, chamfer=lip_height/2, anchor=BOTTOM, orient=RIGHT);
                    }
            children();
        }
    }

}