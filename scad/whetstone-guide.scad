include <BOSL2/std.scad>
include <BOSL2/walls.scad>

$fn=90;

/* [Basic] */
// Whetstone width (in mm)
stone_width  =  61; // [10:1:150]
// Whetstone height (in mm)
stone_height =  28; // [10:1:100]
// Whetstone length (in mm)
stone_length = 180; // [100:1:300]
// Guide length (in mm)
guide_length =  60; // [30:1:100]
// Guide lift (spacing between stone and guide, in mm)
guide_lift   =   1; // [0:0.1:5]
// Guide thickness (in mm)
guide_thick  =   3; // [0:0.1:6]
// Guide angle 1 (in degrees)
guide_angle_1         = 20; // [5:0.1:45]
// Enable guide angle 2
guide_angle_2_enabled = false;
// Guide angle 2 (in degrees)
guide_angle_2         = 17.5; // [5:0.1:45]
// Enable guide angle 3
guide_angle_3_enabled = false;
// Guide angle 3 (in degrees)
guide_angle_3         = 15; // [5:0.1:45]
// Enable guide angle 4
guide_angle_4_enabled = false;
// Guide angle 4 (in degrees)
guide_angle_4         = 25; // [5:0.1:45]
guide_angles = concat(
    [guide_angle_1],
    guide_angle_2_enabled ? [guide_angle_2] : [],
    guide_angle_3_enabled ? [guide_angle_3] : [],
    guide_angle_4_enabled ? [guide_angle_4] : []
);

/* [Advanced] */
base_height      =  3;
base_hex_strut   =  5;
base_hex_spacing = 18;
base_edge_height = 10;
base_edge_length =  8;
base_rounding    =  7;
rail_width       = 20;
rail_d           = 15;
rail_drain_width =  2;
// 3D print layer height (in mm)
layer_height     =  0.2;
// Rail margin (clearing between the rail bed and the rail skates)
rail_margin      =  0.2; // [0:0.1:2]

/* [Preview settings] */
preview_stone = true;
preview_base  = true;
preview_guide = true;
debug         = false;

module stone() {
    recolor("red")
    cuboid(
        size=[stone_width, stone_length, stone_height/2],
        anchor=BOTTOM)

    recolor("white")
    position(TOP)
    cuboid(
        size=[stone_width, stone_length, stone_height/2],
        anchor=BOTTOM);
}

module base() {
    diff()
    
    // Bottom, framed hex plate. Same size as stone
    hex_panel(
        shape=[
            stone_width,
            stone_length,
            base_height],
        strut=base_hex_strut,
        spacing=base_hex_spacing,
        anchor=BOT) {
        
        // Edges in the length direction so the stone won't slide
        yflip_copy()
        position(FWD+BOT)
        cuboid(
            size=[
                stone_width,
                base_edge_length,
                base_height+base_edge_height],
            anchor=BACK+BOT);

        // Rail bed
        xflip_copy()
        position(RIGHT+BOT)
        cuboid(
            size=[
                rail_width,
                stone_length+2*base_edge_length,
                base_height+base_edge_height],
            anchor=LEFT+BOT,
            rounding=base_rounding,
            edges=[RIGHT+FWD, RIGHT+BACK]) {

            // Rail groove
            tag("remove")
            position(TOP)
            up(rail_d*0.1) // Lift it 10% to open the bed angle
            orient(FWD)
            cyl(h=stone_length, d=rail_d);
            
            // Rail drain
            alpha = asin(2*rail_drain_width/rail_d);
            lift = rail_d/2 * (1 - cos(alpha));
            tag("remove")
            position(TOP)
            down(rail_d*0.4-lift)
            cuboid(
                size=[rail_drain_width, stone_length, base_height+base_edge_height+1],
                rounding=-rail_drain_width/2,
                edges=[TOP+LEFT, TOP+RIGHT],
                anchor=TOP);
        }
    }
}

module construction_frame(size, anchor=CENTER, spin=0, orient=UP, debug=0) {
    attachable(anchor, spin, orient, size=size) {
        union() {
            if ($preview && debug > 0) {
                xflip_copy(size[0]/2)
                yflip_copy(size[1]/2)
                #cuboid(
                    size=[debug, debug, size[2]],
                    anchor=RIGHT+BACK);

                xflip_copy(size[0]/2)
                zflip_copy(size[2]/2)
                #cuboid(
                    size=[debug, size[1], debug],
                    anchor=RIGHT+TOP);

                yflip_copy(size[1]/2)
                zflip_copy(size[2]/2)
                #cuboid(
                    size=[size[0], debug, debug],
                    anchor=BACK+TOP);
            }
        }
        children();
    }
}

module guide(angle=20) {
    width = stone_width + rail_width;
    height = stone_height - base_edge_height - rail_d*0.1;

    diff()
    construction_frame(
        size=[width, guide_length, height],
        anchor=BOT,
        debug=debug?1:0) {
        
        // Main body
        position(BOT)
        cuboid(
            size=[
                width+guide_thick,
                guide_length,
                // allow a maximum of 40° => len*√2
                height+guide_lift+guide_thick+guide_length*sqrt(2)],
            anchor=BOT) {
            
            // Inner cutout
            tag("remove")
            position(BACK+BOT)
            up(height+guide_lift)
            xrot(-angle)
            cuboid([width-guide_thick, 200, 100], anchor=TOP)

            // Outer cutout
            tag("remove")
            position(TOP)
            up(guide_thick)
            cuboid([width+guide_thick+1, 200, 100], anchor=BOT);

            // Angle text
            tag("remove")
            position(LEFT+BOT)
            up(rail_d/2+3)
            orient(LEFT)
            linear_extrude(height = 1, center=true)
            text(
                text=str(angle, "°"),
                halign="center",
                size=13);
        }
        
        // Rail skates
        skate_d = rail_d - 2*rail_margin;
        tag("keep")
        xflip_copy(width/2)
        position(DOWN)
        orient(BACK)
        cyl(h=guide_length, d=skate_d, chamfer=2*layer_height, chamfang=72);
    }
}

if ($preview) {
    if (preview_stone)
        up(base_height)
        stone();
    if (preview_base)
        color("#a0a0ff")
        base();
    if (preview_guide)
        up(base_height+base_edge_height+rail_d*0.1)
        color("#ffa0a0")
        guide(guide_angle_1);
} else {
    left((stone_width+2*rail_width)/2)
    base();

    spacing = (stone_width+2*rail_width)/2;
    back((len(guide_angles)-1)*spacing/2)
    right((stone_width+2*rail_width)/2)
    for (i = [0:len(guide_angles)-1]) {
        angle = guide_angles[i];
        fwd(i*spacing)
        up(guide_length/2)
        zrot(90 + (i%2 * 180))
        xrot(90)
        guide(angle=angle);
    }
}

echo(str(
        "--camera=",
        $vpt[0], ",", $vpt[1], ",", $vpt[2], ",",
        $vpr[0], ",", $vpr[1], ",", $vpr[2], ",",
        $vpd
    ));