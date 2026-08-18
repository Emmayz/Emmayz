// ============================================================================
//  SOUNDING ROCKET — VERTICAL STATIC-TEST ASSEMBLY
//  Parametric CAD model (OpenSCAD source)
//  Drawing No. EMZ-RKT-0002  |  Rev A  |  Units: mm
//
//  Rocket stands upright (nose up, engine down) in a vertical hold-down /
//  launch-tower fixture and fires downward into a flame deflector. The same
//  airframe as EMZ-RKT-0001, re-oriented for a vertical hot-fire.
//
//  Open in OpenSCAD (free, openscad.org). F5 preview, F6 render, then
//  File > Export to STL / OFF / AMF / 3MF / DXF for use in any CAD tool.
// ============================================================================

$fn = 64;                       // global smoothness

// ---------------------------- PARAMETERS ------------------------------------
BODY_D      = 450;              // body outer diameter (mm)
BODY_R      = BODY_D/2;

L_NOSE      = 1150;            // nose cone length
L_PAYLOAD   = 550;            // payload / avionics bay
L_IDBAND    = 350;            // red id band section
L_OXTANK    = 1500;           // oxidizer tank
L_INTER     = 180;            // interstage ring
L_FUEL      = 1500;           // fuel tank
L_AFT       = 550;            // aft / thrust structure (tapers)
AFT_R       = BODY_R*0.82;    // aft radius at engine mount

THROAT_R    = 90;
EXIT_R      = 340;
BELL_L      = 600;

OAL = L_NOSE + L_PAYLOAD + L_IDBAND + L_OXTANK + L_INTER + L_FUEL + L_AFT;

// Vertical-stand parameters
PLAT   = 980;                  // engine-mount height above pad (low, grounded)
BASE_Z = PLAT + OAL;           // world Z of nose tip
TX     = BODY_R + 1350;        // service-tower centre offset (+X side)
PADR   = 6000;                 // ground-pad radius (shrink for tight previews)
NOZ_Z  = PLAT - (160 + BELL_L);// approx nozzle-exit height above pad (~220 mm)
SPAN   = 1000;                 // pedestal column half-spacing

echo(str("OVERALL LENGTH (nose->mount) = ", OAL, " mm"));
echo(str("STAND HEIGHT (pad->nose tip) = ", BASE_Z, " mm"));
echo(str("NOZZLE EXIT above pad = ", NOZ_Z, " mm"));

// =================== HELPER MODULES =========================================
module hoop(r, t=6) rotate([0,90,0]) rotate_extrude() translate([r,0,0]) circle(r=t/2);

module ogive_nose(len, base_r){
    steps = 40;
    rotate([0,90,0])
    rotate_extrude()
      polygon(points = concat(
        [ for(i=[0:steps]) let(t=i/steps) [ base_r*sqrt(t), t*len ] ],
        [ [0, len] ]
      ));
}
module body_section(len, r1, r2){ rotate([0,-90,0]) cylinder(h=len, r1=r1, r2=r2); }
module nozzle_bell(){
    steps = 28;
    rotate([0,-90,0])
    rotate_extrude()
      polygon(points = concat(
        [ for(i=[0:steps]) let(t=i/steps)
            [ THROAT_R + (EXIT_R-THROAT_R)*pow(t,0.7), t*BELL_L ] ],
        [ for(i=[steps:-1:0]) let(t=i/steps)
            [ (THROAT_R + (EXIT_R-THROAT_R)*pow(t,0.7))-8, t*BELL_L ] ]
      ));
}
module fin(root=500, tip=220, span=420, sweep=320, thick=20){
    linear_extrude(height=thick, center=true)
      polygon([ [0,0], [root,0], [sweep+tip, span], [sweep, span] ]);
}

// =================== ROCKET (built along +X, nose at +X) ====================
module rocket(){
    color("gainsboro") mirror([1,0,0]) ogive_nose(L_NOSE, BODY_R);
    color("silver") sphere(r=18);
    px = -L_NOSE;
    translate([px,0,0]) color("whitesmoke") body_section(L_PAYLOAD, BODY_R, BODY_R);
    translate([px - L_PAYLOAD*0.5, 0, BODY_R-2]) color("dimgray") cube([180,120,12], center=true);
    px2 = px - L_PAYLOAD;
    translate([px2,0,0]) color("firebrick") body_section(L_IDBAND, BODY_R, BODY_R);
    px3 = px2 - L_IDBAND;
    translate([px3,0,0]) color("gainsboro") body_section(L_OXTANK, BODY_R, BODY_R);
    translate([px3,0,0]) color("silver") hoop(BODY_R+2, 8);
    px4 = px3 - L_OXTANK;
    translate([px4,0,0]) color("firebrick") body_section(L_INTER, BODY_R, BODY_R);
    translate([px4 - L_INTER/2,0,0]) color("silver") hoop(BODY_R+4, 12);
    px5 = px4 - L_INTER;
    translate([px5,0,0]) color("gainsboro") body_section(L_FUEL, BODY_R, BODY_R);
    px6 = px5 - L_FUEL;
    translate([px6,0,0]) color("whitesmoke") body_section(L_AFT, BODY_R, AFT_R);
    px7 = px6 - L_AFT;
    // cable raceway
    color("dimgray") hull(){
        translate([px3+50, BODY_R+28, 0]) sphere(r=30);
        translate([px7,    BODY_R+28, 0]) sphere(r=30);
    }
    // fins x4
    for(a=[0:90:270]) rotate([a,0,0])
        translate([px7+20, BODY_R*0.9, 0]) color("firebrick") rotate([90,0,180]) fin();
    // engine
    translate([px7,0,0]) color("dimgray") rotate([0,-90,0]) cylinder(h=40, r=AFT_R, center=true);
    translate([px7-60,0,0]) color("gray") rotate([0,-90,0]) cylinder(h=180, r1=AFT_R*0.7, r2=THROAT_R);
    translate([px7-160,0,0]) color("peru") mirror([1,0,0]) nozzle_bell();
    for(i=[1:6]) let(t=i/7, rr=THROAT_R+(EXIT_R-THROAT_R)*pow(t,0.7))
      translate([px7-160 - t*BELL_L, 0, 0]) color("silver") hoop(rr, 6);
    translate([px7-30, -180, 120]) color("silver") sphere(r=70);
}

// place rocket vertical: nose up (+Z), engine down
module rocket_vertical(){
    translate([0,0,BASE_Z]) rotate([0,-90,0]) rocket();
}

// =================== VERTICAL TEST STAND ====================================
// Short, heavy braced pedestal carrying the engine mount just under 1 m up.
module thrust_pedestal(){
    colW = 300;
    // four columns
    for(sx=[-1,1], sy=[-1,1])
      color("lightsteelblue")
        translate([sx*SPAN, sy*SPAN, (PLAT-120)/2]) cube([colW,colW,PLAT-120], center=true);
    // perimeter ring beams, top and bottom
    for(z=[240, PLAT-160]) color("slategray"){
        translate([0, SPAN,z]) cube([2*SPAN+colW,180,150], center=true);
        translate([0,-SPAN,z]) cube([2*SPAN+colW,180,150], center=true);
        translate([ SPAN,0,z]) cube([180,2*SPAN+colW,150], center=true);
        translate([-SPAN,0,z]) cube([180,2*SPAN+colW,150], center=true);
    }
    // X-braces on all four faces
    brace = 2*SPAN*1.28;
    for(sy=[-1,1]) for(r=[42,-42]) color("slategray")
        translate([0, sy*SPAN, PLAT*0.42]) rotate([0,r,0]) cube([brace,95,95], center=true);
    for(sx=[-1,1]) for(r=[42,-42]) color("slategray")
        translate([sx*SPAN, 0, PLAT*0.42]) rotate([r,0,0]) cube([95,brace,95], center=true);
    // top deck with central exhaust hole
    color("slategray") translate([0,0,PLAT-60])
      difference(){
        cube([2*SPAN+colW+260, 2*SPAN+colW+260, 120], center=true);
        cylinder(h=200, r=EXIT_R+150, center=true);
      }
    // engine thrust-mount collar
    color("steelblue") translate([0,0,PLAT])
      difference(){
        cylinder(h=210, r=AFT_R+120, center=true);
        cylinder(h=230, r=AFT_R+25,  center=true);
      }
}

// Flame trench at grade with an angled deflector turning the jet toward -Y.
module flame_trench(){
    color("dimgray"){
        // channel floor slab, running out toward -Y
        translate([0,-1500,30]) cube([1750,3600,60], center=true);
        // side walls
        for(sx=[-1,1]) translate([sx*875,-1500,340]) cube([90,3600,620], center=true);
        // head wall directly under the nozzle (+Y end of channel)
        translate([0,320,340]) cube([1750,90,620], center=true);
    }
    // angled deflector ramp — ridge just under the nozzle (z=200), sloping
    // down to the -Y end of the channel; turns the downward jet sideways.
    W2 = 800;
    color("slategray")
      polyhedron(
        points=[
          [-W2, 300, 200], [-W2, 300, 40], [-W2, -2500, 40],
          [ W2, 300, 200], [ W2, 300, 40], [ W2, -2500, 40] ],
        faces=[ [0,1,2],[5,4,3],[0,2,5,3],[0,3,4,1],[1,4,5,2] ]);
}

// Service / umbilical tower on the +X side with two work platforms.
module service_tower(){
    postR = 90; foot = 330;
    top = BASE_Z + 120;
    // 4 vertical posts + base plate
    color("dimgray") translate([TX,0,60]) cube([2*foot+3*postR, 2*foot+3*postR, 120], center=true);
    for(sx=[-1,1], sy=[-1,1])
      color("lightsteelblue")
        translate([TX+sx*foot, sy*foot, top/2]) cube([2*postR,2*postR,top], center=true);
    // horizontal rungs (square frames)
    for(z=[350:1050:top-200]) color("slategray"){
        translate([TX, foot, z]) cube([2*foot+2*postR, 2*postR, 85], center=true);
        translate([TX,-foot, z]) cube([2*foot+2*postR, 2*postR, 85], center=true);
        translate([TX+foot,0,z]) cube([2*postR, 2*foot, 85], center=true);
        translate([TX-foot,0,z]) cube([2*postR, 2*foot, 85], center=true);
    }
    // outboard X-braces on the +X face
    for(z=[400:2100:top-1300]) color("slategray"){
        translate([TX+foot,0,z+520]) rotate([ 40,0,0]) cube([2*postR,85,1500], center=true);
        translate([TX+foot,0,z+520]) rotate([-40,0,0]) cube([2*postR,85,1500], center=true);
    }
    // two work platforms reaching toward the rocket (with body clearance)
    for(pz=[PLAT+OAL*0.35, PLAT+OAL*0.72]) color("slategray")
      translate([(TX-foot+BODY_R+180)/2, 0, pz-70])
        difference(){
          cube([TX-foot-(BODY_R+180), 2*foot+120, 70], center=true);
          translate([-(TX-foot-(BODY_R+180))/2,0,0]) cylinder(h=120, r=BODY_R+120, center=true);
        }
}

// Hold-down / guide clamp arms restraining the airframe.
module holddown_arms(){
    for(hz=[PLAT+320, PLAT+OAL*0.5, PLAT+OAL*0.85]){
        color("gold")
          translate([0,0,hz])
          difference(){
            cylinder(h=170, r=BODY_R+65, center=true);
            cylinder(h=190, r=BODY_R+6,  center=true);
          }
        for(sy=[-1,1])
          color("goldenrod")
            translate([(BODY_R+65+TX-330)/2, sy*175, hz])
              cube([TX-330-(BODY_R+65), 85, 100], center=true);
    }
}

// =================== FULL ASSEMBLY ==========================================
module assembly(){
    rocket_vertical();
    thrust_pedestal();
    flame_trench();
    service_tower();
    holddown_arms();
    // ground pad
    color("darkslategray") translate([0,0,-5]) cylinder(h=10, r=PADR);
}

assembly();
