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
PLAT   = 1600;                 // thrust-table / engine-mount height above pad
BASE_Z = PLAT + OAL;           // world Z of nose tip
TX     = BODY_R + 1500;        // umbilical tower centre offset (+X side)
PADR   = 6000;                 // ground-pad radius (shrink for tight previews)
NOZ_Z  = PLAT - (160 + BELL_L);// approx nozzle-exit height above pad

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
module thrust_table(){
    // raised deck with central exhaust hole
    color("slategray")
    translate([0,0,PLAT-70])
      difference(){
        cube([2800,2800,140], center=true);
        cylinder(h=200, r=EXIT_R+220, center=true);
      }
    // four legs
    for(a=[45:90:315])
      rotate([0,0,a]) translate([1250,0,0])
        color("lightsteelblue") translate([0,0,(PLAT-140)/2]) cube([260,260,PLAT-140], center=true);
    // diagonal cross-braces between legs (outer ring)
    for(a=[45:90:315])
      rotate([0,0,a+45]) translate([1250*sqrt(0.5)*sqrt(2),0,PLAT*0.45])
        color("lightsteelblue") rotate([90,0,0]) cube([60,1500,60], center=true);
    // engine thrust-mount collar around the throat, sitting on the deck
    color("steelblue")
    translate([0,0,PLAT])
      difference(){
        cylinder(h=220, r=AFT_R+130, center=true);
        cylinder(h=240, r=AFT_R+30,  center=true);
      }
}

module flame_deflector(){
    // apex-up cone that splits the downward exhaust, on the pad centreline
    color("dimgray") cylinder(h=1150, r1=1500, r2=0);
    // surrounding lip / trench rim
    color("slategray")
      translate([0,0,60])
      difference(){
        cylinder(h=120, r=2400);
        cylinder(h=140, r=1900, center=false);
      }
}

// umbilical / hold-down launch tower on the +X side
module launch_tower(){
    postR = 90; foot = 350;          // posts on a 700 x 700 column
    top = BASE_Z + 150;
    // 4 vertical posts
    for(sx=[-1,1], sy=[-1,1])
      color("lightsteelblue")
        translate([TX+sx*foot, sy*foot, top/2]) cube([2*postR,2*postR,top], center=true);
    // horizontal rungs (square frames) up the tower
    for(z=[300:1100:top-200]){
      color("slategray"){
        translate([TX, 0, z]) cube([2*foot+2*postR, 2*postR, 90], center=true);      // front/back run in x
        translate([TX, -foot, z]) rotate([0,0,90]) cube([2*foot, 2*postR, 90], center=true);
        translate([TX,  foot, z]) rotate([0,0,90]) cube([2*foot, 2*postR, 90], center=true);
      }
    }
    // outboard diagonal braces (X pattern on the +X face)
    for(z=[300:2200:top-1200])
      color("slategray")
        translate([TX+foot, 0, z+550]) rotate([45,0,0]) cube([2*postR,90,1500], center=true);
}

// hold-down / guide arms clamping the airframe at three stations
module holddown_arms(){
    for(hz=[PLAT+450, PLAT+OAL*0.45, PLAT+OAL*0.82]){
        // clamp collar around the body
        color("gold")
          translate([0,0,hz])
          difference(){
            cylinder(h=180, r=BODY_R+70, center=true);
            cylinder(h=200, r=BODY_R+6,  center=true);
          }
        // two arms reaching to the tower
        for(sy=[-1,1])
          color("goldenrod")
            translate([(BODY_R+70+TX-350)/2, sy*180, hz])
              cube([TX-350-(BODY_R+70), 90, 110], center=true);
    }
}

// =================== FULL ASSEMBLY ==========================================
module assembly(){
    rocket_vertical();
    thrust_table();
    flame_deflector();
    launch_tower();
    holddown_arms();
    // ground pad
    color("darkslategray") translate([0,0,-5]) cylinder(h=10, r=PADR);
}

assembly();
