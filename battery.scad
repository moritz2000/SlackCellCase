include <libs/BOSL2/std.scad>

//battery() show_anchors();
battery_dim = [52.5, 41, 5];


module battery(anchor = CENTER, spin = 0, orient = UP){
    recolor("purple") cuboid(battery_dim, anchor = anchor, spin = spin, orient = orient, rounding = 2.5, edges = "X");
}
