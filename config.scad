include <BOSL2/std.scad>

//these includes are made to base some dimensions on the variables in them
include <loadCell.scad>
include <pcb.scad>
include <battery.scad>

//ignore message about changes in BOSL api
$align_msg = false;

//This file contains most of the global variables, so that the different scad files can all access them

///////////////////////////////////
//Settings for Preview and Rendering
//Only generate the round features with high detail when it is rendering for exporting the stl. This gives us faster previews
$fa = $preview ? 10 : 1;
$fs = $preview ? 1 : 0.25;

//used to get section views. Use only false or $preview. This way the render is unaffected.
show_only_left_half = false;//$preview;
show_only_front_half = false;//$preview;
show_only_right_half = false;//$preview;

//separate parts by this amount in x for rendering, for easy inspection
render_spacing = 100;

//////////////////////////////////////
//Slicer specific settings for the PETG parts (case and lid)
layer_height = 0.3;
//Recommended wall thickness from slicer
//With Prusa Slicer, read them of in Print Settings -> Layer and Perimeters -> Vertical Shells
s2_walls = 1.14;
s4_walls = 2.21;
s6_walls = 3.28;

/////////////////////////////////////
//These settings define the dimensions of the case. Some dimensions however are derived from the refernece parts (pcb, loadcell and battery).

//gap to leave between the inner walls of the case and the outer dimensions of the load cell
cell_to_case_gap_xy = 3.5;
cell_to_case_gap_z = 2;

//minimum wall thickness in xy and z
case_wall = s6_walls;
case_rounding = case_wall;
case_screw_rounding = 2;


gasket_thickness = 1.25;
pcb_to_battery_spacing = 4;

//Variables for corner piece out of TPU which fixes the loadcell inside of the case, while still allowing it to flex
cell_holder_width = 10;
cell_holder_rounding = case_rounding - case_wall;
//prevents squezing the loadcell too much, which would already exert a force.
case_cell_holder_stoppers_gap = 0.3;



//Config for the window that get's inserted to protect the screen. I cut mine out of an empty 3d printing filament spool which is PC material, and is rounded.
//For a flat one, the variables and module "pcb_display_window" have to be slightly changed

//sets how many mm the window will side below the outside surface of the lid
window_inset = 0.9;
window_dim = [33, 24.25, 6]; //with a curved window, this is measured when the window is sitting on a flat surface, from the surface to the top most point
window_radius = 58;
//Vector for defining for x and y material to leave besides the window, the higher the number the less you'll see on the display later (worse viewing angle)
//z is just there for making the cutout
window_border = [1.5, 0.5, -case_wall];
window_holder_wall = s4_walls;
//leave some space for glueing it in
window_slop = 0.4;

//prevents pressure on the case to damage the display
display_to_window_dist = 0.2; //so small, because window is curved


////////////////////////
//Calculated dimensions:

case_inner_dim_xy = [loadcell_dim.x, loadcell_dim.y] + repeat(2*cell_to_case_gap_xy, 2);
case_inner_dim_z = loadcell_dim.z + 2*cell_to_case_gap_z;

case_outer_dim_xy = case_inner_dim_xy + repeat(2*case_wall, 2);

//distance between inner top surface of the lid and the topmost surface from the display in z direction
lid_to_display_dist = window_dim.z - case_wall + window_inset + display_to_window_dist;

lid_internal_height = lid_to_display_dist + pcb_dim.z + pcb_to_battery_spacing + battery_dim.z;

//transform of the pcb relativ to BOTTOM of lid
//Usage: multmatrix(pcb_transfrom_matrix)
//         pcb(); //or anything else you want to have in this transformation
pcb_transform_matrix = up(lid_internal_height + gasket_thickness - lid_to_display_dist) * zrot(90);