// ============================================================================
//  SOUNDING ROCKET — HORIZONTAL STATIC-TEST ASSEMBLY
//  Parametric CAD model (OpenSCAD source)
//  Drawing No. EMZ-RKT-0001  |  Rev A  |  Units: mm
//
//  Open in OpenSCAD (free, openscad.org). Press F5 to preview, F6 to render,
//  then File > Export to STL / OFF / AMF / 3MF / DXF for use in any CAD tool.
//  A rendered model can be imported into Fusion 360 / FreeCAD / SolidWorks
//  via STL/STEP conversion.
// ============================================================================

$fn = 96;                       // global smoothness

// ---------------------------- PARAMETERS ------------------------------------
BODY_D      = 450;              // body outer diameter (mm)
BODY_R      = BODY_D/2;
WALL        = 6;               // airframe wall thickness

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

// derived overall length (nose tip .. engine mount)
OAL = L_NOSE + L_PAYLOAD + L_IDBAND + L_OXTANK + L_INTER + L_FUEL + L_AFT;

// Test-stand parameters
CL_H        = 950;            // rocket centreline height above pad
CRADLE_ARC  = 130;           // saddle wrap angle (deg)

echo(str("OVERALL LENGTH (nose->mount) = ", OAL, " mm"));
echo(str("BODY DIAMETER = ", BODY_D, " mm"));

// =================== HELPER MODULES =========================================
module hoop(r, t=6) rotate([0,90,0]) rotate_extrude() translate([r,0,0]) circle(r=t/2);

// Rocket built along +X, nose at +X. Origin at nose tip.
module ogive_nose(len, base_r){
    // approximate ogive by stacked discs
    steps = 40;
    rotate([0,90,0])
    rotate_extrude()
      polygon(points = concat(
        [ for(i=[0:steps]) let(t=i/steps) [ base_r*sqrt(t), t*len ] ],
        [ [0, len] ]
      ));
}

module body_section(len, r1, r2){
    translate([0,0,0])
    rotate([0,-90,0])
      cylinder(h=len, r1=r1, r2=r2);
}

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

// =================== ROCKET ASSEMBLY ========================================
module rocket(){
    x = 0;
    // nose (tip at x=0, base at x=-L_NOSE going -X). We build toward -X.
    color("gainsboro"){
        translate([0,0,0]) mirror([1,0,0]) ogive_nose(L_NOSE, BODY_R);
    }
    // metal tip
    color("silver") sphere(r=18);

    // running position (base of nose)
    px = -L_NOSE;

    // payload bay
    translate([px,0,0]) color("whitesmoke") body_section(L_PAYLOAD, BODY_R, BODY_R);
    // avionics hatch
    translate([px - L_PAYLOAD*0.5, 0, BODY_R-2]) color("dimgray")
        cube([180,120,12], center=true);

    px2 = px - L_PAYLOAD;
    // red id band
    translate([px2,0,0]) color("firebrick") body_section(L_IDBAND, BODY_R, BODY_R);

    px3 = px2 - L_IDBAND;
    // oxidizer tank
    translate([px3,0,0]) color("gainsboro") body_section(L_OXTANK, BODY_R, BODY_R);
    translate([px3,0,0]) color("silver") hoop(BODY_R+2, 8);

    px4 = px3 - L_OXTANK;
    // interstage
    translate([px4,0,0]) color("firebrick") body_section(L_INTER, BODY_R, BODY_R);
    translate([px4 - L_INTER/2,0,0]) color("silver") hoop(BODY_R+4, 12);

    px5 = px4 - L_INTER;
    // fuel tank
    translate([px5,0,0]) color("gainsboro") body_section(L_FUEL, BODY_R, BODY_R);

    px6 = px5 - L_FUEL;
    // aft structure (taper to AFT_R)
    translate([px6,0,0]) color("whitesmoke") body_section(L_AFT, BODY_R, AFT_R);

    px7 = px6 - L_AFT;    // engine mount face

    // cable raceway along top
    color("dimgray")
      hull(){
        translate([px3+50, BODY_R+28, 0]) sphere(r=30);
        translate([px7,    BODY_R+28, 0]) sphere(r=30);
      }

    // fins x4
    for(a=[0:90:270])
      rotate([a,0,0])
        translate([px7+20, BODY_R*0.9, 0])
          color("firebrick") rotate([90,0,180]) fin();

    // ---- engine ----
    // mount ring
    translate([px7,0,0]) color("dimgray") rotate([0,-90,0]) cylinder(h=40, r=AFT_R, center=true);
    // convergent
    translate([px7-60,0,0]) color("gray")
      rotate([0,-90,0]) cylinder(h=180, r1=AFT_R*0.7, r2=THROAT_R);
    // nozzle bell (opens toward -X)
    translate([px7-160,0,0]) color("peru") mirror([1,0,0]) nozzle_bell();
    // cooling hoops
    for(i=[1:6]) let(t=i/7, rr=THROAT_R+(EXIT_R-THROAT_R)*pow(t,0.7))
      translate([px7-160 - t*BELL_L, 0, 0]) color("silver") hoop(rr, 6);
    // turbopump
    translate([px7-30, -180, 120]) color("silver") sphere(r=70);
}

// =================== STATIC TEST STAND ======================================
module cradle_support(){
    bw = 1200; bd = 900;
    // base plate
    color("slategray") translate([0,0,30]) cube([bd,bw,60], center=true);
    // legs
    for(z=[-420,420]){
        color("lightsteelblue")
          translate([0,z, (CL_H-120)/2+60]) cube([90,90,CL_H-120], center=true);
    }
    // cross beam
    color("lightsteelblue") translate([0,0,CL_H-20]) cube([120,bw,100], center=true);
    // saddle (yellow) — partial tube that hugs the body
    color("gold")
      translate([0,0,CL_H]) rotate([0,90,0])
        difference(){
          cylinder(h=220, r=BODY_R+50, center=true);
          cylinder(h=240, r=BODY_R+20, center=true);
          // cut to arc opening on top
          translate([0,-BODY_R*2,0]) cube([BODY_R*4, BODY_R*4, 260], center=true);
        }
    // rubber liner
    color("dimgray")
      translate([0,0,CL_H]) rotate([0,90,0])
        difference(){
          cylinder(h=220, r=BODY_R+18, center=true);
          cylinder(h=240, r=BODY_R+8, center=true);
          translate([0,-BODY_R*2,0]) cube([BODY_R*4, BODY_R*4, 260], center=true);
        }
}

module thrust_wall(){
    color("slategray") translate([0,0,1100]) cube([250,2200,2200], center=true);
    for(z=[-700,700]) color("lightsteelblue")
        translate([-200,z,1100]) cube([500,80,2000], center=true);
    // load cell toward rocket
    color("silver") translate([280,0,CL_H]) rotate([0,90,0]) cylinder(h=300, r=120, center=true);
    color("gold")   translate([280,0,CL_H]) rotate([0,90,0]) cylinder(h=50,  r=130, center=true);
}

module flame_deflector(){
    color("slategray")
    translate([0,-700,20]) rotate([-90,0,0])
      linear_extrude(height=1400)
        polygon([[-600,0],[600,0],[600,350],[0,700],[-600,350]]);
}

// =================== FULL ASSEMBLY ==========================================
module assembly(){
    // place rocket horizontally at centreline height
    // rocket local origin is nose tip; shift so it sits centred on stand
    translate([OAL*0.55, 0, CL_H])
        rocket();

    // fore & aft cradle supports (under body, not the engine)
    translate([OAL*0.55 - L_NOSE - 600, 0, 0]) cradle_support();
    translate([OAL*0.55 - OAL + 900,     0, 0]) cradle_support();

    // thrust reaction wall behind engine (-X end)
    translate([OAL*0.55 - OAL - 700, 0, 0]) thrust_wall();

    // flame deflector under nozzle
    translate([OAL*0.55 - OAL - 100, 0, 0]) flame_deflector();

    // ground pad
    color("darkslategray") translate([0,0,-5]) cylinder(h=10, r=6000);
}

assembly();
