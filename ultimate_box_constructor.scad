//////////////////////////////////////////////////////////
////****MAIN SETTINGS****/////////////////////////////////
//////////////////////////////////////////////////////////

//quality
$fn = 32;

//0 - no lid
//1 - yes lid
lid = 1;
lid_size_ratio = 0.3;

//size of box in milimeters(openSCAD is unitless, so scale if needed)
overall_size_x = 100;
overall_size_y = 100;
overall_size_z = 100;

wall_thickness = 2; //wall thickness in cm

roundness = 5; //roundness of the box

//0 - whole
//1 - horizontal
//2 - x aligned
//3 - y aligned
roundness_type = 0;

internal_sections_thickness = 2; //internal sections thickness

internal_sections = [ 
                    //relative        | angle        | length  |relative |
                    //coordinates     | around z     | of the  | height  |
                    //of the middle   | (by default  | section |         |
                    //of the section  | sections are |         |         |
                    //                | alligned     |         |         |
                    //                | with x)      |         |         |
                        [ [0.5, 0.5],   90,             200,        1 ],
                        [ [0.7, 0.7],   10 ,             10,       0.5 ]
                    ];

//////////////////////////////////////////////////////////////////
////****ADVANCED SETTINGS****/////////////////////////////////////
//////////////////////////////////////////////////////////////////

//gap between body and lid
lid_gap = 0.5;

//box type 0 properties
body_roundness_reducer_multiplyer = 1;

//////////////////////////////////////////////////////////////////
////****PRE CALCULATION****///////////////////////////////////////
//////////////////////////////////////////////////////////////////

body_size_x = overall_size_x;
body_size_y = overall_size_y;
body_size_z = lid ? overall_size_z - roundness*body_roundness_reducer_multiplyer - wall_thickness : overall_size_z;

body_internal_size_x = body_size_x - wall_thickness*2;
body_internal_size_y = body_size_y - wall_thickness*2;
body_internal_size_z = body_size_z - wall_thickness;

main_body_internal_center = [body_internal_size_x/2.0,
                             body_internal_size_y/2.0,
                             body_internal_size_z/2.0];

lid_size_x = overall_size_x + wall_thickness*2 + lid_gap;
lid_size_y = overall_size_y + wall_thickness*2 + lid_gap;
lid_size_z = overall_size_z*lid_size_ratio;

module main_body_space(){
    translate([wall_thickness+lid_gap, wall_thickness+lid_gap, 0]){
        children();
    }
}

module lid_space(){
    translate([(overall_size_x)*1.5, 0, 0]){
        children();
    }
}

module main_body_internal_space(){
    main_body_space(){
        translate([wall_thickness, wall_thickness, wall_thickness]){
            children();
        }
    }
}

//////////////////////////////////////////////////////////////////
////****EXECUTION PART*****///////////////////////////////////////
//////////////////////////////////////////////////////////////////

//body cube with roundness
module rounded_cube(_x, _y, _z, _r){
    translate([_r, _r, _r]){
        minkowski(){
            cube([_x-_r*2,
                  _y-_r*2,
                  _z-_r*2]);
            roundness_object();
        }
    }
}

module inverse_rounded_cube(__x, __y, __z, __r){
    difference(){
        cube(__x*5, __y*5, __z*5, center = true);
        rounded_cube(__x, __y, __z, __r);
    }
}

module top_cut(__x, __y, __z){
    translate([0, 0, __z]){
        _z_size = __z*2;
        translate ([0,0, (_z_size)/2]) cube([__x*3, __y*3, _z_size], center=true);
    }
}

module internal_sections(_internal_sections){
    for (__s = _internal_sections){
        if (__s[0] != undef){
            section_length = __s[2];
            section_width = internal_sections_thickness;
            section_height = body_internal_size_z*__s[3];
            difference(){
//                translate([(0.5 - __s[0][0])*main_body_internal_center.x,
  //                         (0.5 - __s[0][1])*main_body_internal_center.y,
    //                       0]){
                    section_center = [section_length/2.0, section_width/2.0];
                    translate([body_internal_size_x*__s[0][0],
                               body_internal_size_y*__s[0][1],
                               0] - section_center){
                        translate([section_center.x, section_center.y, section_height/2.0]){
                            rotate(a = __s[1], v = [0,0,1]){
                                cube([section_length, section_width, section_height], center = true);
                            }
                        }
                    }
      //          }
                union(){
                    top_cut(body_size_x, body_size_y, body_size_z);
                    inverse_rounded_cube(body_internal_size_x,
                                         body_internal_size_y,
                                         body_internal_size_z*1.1+roundness, roundness);
                }
            }
        }
    }
}

module roundness_object(){
    if (roundness_type == 0){
        sphere(roundness);
    }
    else if (roundness_type == 1){
        cylinder(h = roundness*2, r = roundness, center = true);
    }
    else if (roundness_type == 2){
        rotate(a = 90, v = [1,0,0]){
            cylinder(h = roundness*2, r = roundness, center = true);
        }
    }
    else if (roundness_type == 3){
        rotate(a = 90, v = [0,1,0]){
            cylinder(h = roundness*2, r = roundness, center = true);
        }
    }
}

module cup(x, y, z){
    difference(){
        difference(){
           rounded_cube(x, y, z*1.1+roundness, roundness);
           top_cut(x, y, z);
        }
        //inside cut
        translate([wall_thickness, wall_thickness, wall_thickness]){
           rounded_cube(x - wall_thickness*2, y - wall_thickness*2, z*1.1+roundness - wall_thickness*2, roundness);
        }
    }
}

//body
main_body_space() {
    cup(body_size_x, body_size_y, body_size_z);
}

lid_space(){
    if (lid==1){
        cup(lid_size_x, lid_size_y, lid_size_z);
    }
}

main_body_internal_space(){
    internal_sections(internal_sections);
}