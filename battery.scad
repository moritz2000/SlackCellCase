include <BOSL2/std.scad>

//battery() show_anchors();

module battery(anchor = CENTER, spin = 0, orient = UP){
    recolor("purple") cuboid([52.5, 41, 5], anchor = anchor, spin = spin, orient = orient, rounding = 2.5, edges = "X");
}