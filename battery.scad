include <BOSL2/std.scad>

//battery() show_anchors();

module battery(anchor = CENTER, spin = 0, orient = UP){
    recolor([1, 0, 0.7, 0.2]) cuboid([52.5, 41, 5], anchor = anchor, spin = spin, orient = orient, rounding = 2.5, edges = "X");
}