// =============================================================================
// Custom 3D-Printed Desk Name Plate (Parametric Dual & Non-AMS Design)
// Optimized for Bambu Lab A1 Mini (180 x 180 mm build bed)
// =============================================================================

/* [Text & Typography] */
// Name text displayed on the upper line
name            = "JAGJEET SINGH";
// Designation / subtitle text displayed on the lower line
desig           = "(B.Sc Radiology)";
// Font family and weight (Liberation Sans Bold recommended for clean printability)
fnt             = "Liberation Sans:style=Bold";
// Height / size of the name text in mm (14mm fits safely within 175mm A1 Mini limit)
name_size       = 14;     // [10:0.5:28]
// Height / size of the designation text in mm
desig_size      = 9.5;    // [6:0.5:20]

/* [Plate Dimensions] */
// Spacing between the name and designation lines (mm)
line_gap        = 4.5;    // [2:0.5:15]
// Border margin surrounding the text (mm)
margin          = 3.5;    // [2:0.5:10]
// Base plate thickness (mm)
base_t          = 3.0;    // [1:0.5:6]
// Height of name text when vertically extruded (if slant_name is false) (mm)
name_h          = 8.0;    // [3:0.5:15]

/* [Curved Bend Geometry] */
// Apply curved bend slant to the first text (Name) as well (matching reference)
slant_name      = true;   // [true, false]
// Bend angle of the text in degrees (default 40 deg)
bend_deg        = 40;     // [10:1:60]
// Number of thin slices forming the faceted arc (default 24)
slices          = 24;     // [8:1:48]
// Thickness per slice in mm (ensures >= 0.2mm overlap between slices for watertightness)
slice_t         = 0.85;   // [0.4:0.05:1.5]
// Effective arc radius from hinge line to top of designation text (mm)
arc_radius      = 13.0;   // [5:0.5:30]
// Interpretation frame for lean angle: "from_vertical" or "above_desk"
lean_reference  = "from_vertical"; // ["from_vertical", "above_desk"]

/* [Printing Mode & Non-AMS Options] */
// Printing workflow:
// - "dual_material": AMS / dual-extruder multi-material (exports color.stl & white.stl)
// - "layer_pause": Non-AMS single print with ONE filament swap at base_t (base is Color 1, all text is Color 2)
// - "inlay_assembly": Non-AMS modular assembly (base with recessed pocket + snap-in designation insert)
print_mode      = "dual_material"; // ["dual_material", "layer_pause", "inlay_assembly"]

// Inlay pocket depth in base plate for inlay_assembly mode (mm)
inlay_depth     = 1.0;    // [0.6:0.2:2.0]
// XY clearance tolerance for snap-fit inlay (mm)
inlay_tol       = 0.25;   // [0.1:0.05:0.5]

/* [Print Configuration & Colors] */
base_color      = "orange";
text_color      = "white";
// Part to generate:
// - "all": Complete assembled preview
// - "color": Base plate + Name (for dual_material)
// - "white": Designation text (for dual_material)
// - "layer_pause": Single unified STL for manual layer swap
// - "assembly_base": Base with recessed socket (for inlay_assembly)
// - "assembly_insert": Standalone designation insert with mating tab (for inlay_assembly)
part            = "all";  // ["all", "color", "white", "layer_pause", "assembly_base", "assembly_insert"]
// Orient 45 degrees along the 245mm bed diagonal (for names exceeding 175mm)
print_diagonal  = false;

// =============================================================================
// Geometric Calculations & Constraints Validation
// =============================================================================

// 1. Effective lean angle interpretation:
eff_bend_deg = (lean_reference == "above_desk") ? (90 - bend_deg) : bend_deg;

// 2. Overhang validation for support-free printing:
max_overhang = eff_bend_deg;
echo(str("--- Overhang Analysis ---"));
echo(str("Lean reference: '", lean_reference, "', Bend angle: ", bend_deg, " deg"));
echo(str("Effective angle above desk: ", 90 - eff_bend_deg, " deg"));
echo(str("Max overhang angle from vertical: ", max_overhang, " deg"));
if (max_overhang > 45) {
    echo(str("WARNING: Overhang angle (", max_overhang, " deg) exceeds 45 degrees! Supports may be required."));
} else {
    echo(str("Overhang Check PASS: Max overhang is ", max_overhang, " deg (<= 45 deg). Completely support-free!"));
}

// 3. Slice overlap verification for watertight solid:
max_gap = arc_radius * sin(eff_bend_deg / slices);
min_overlap = slice_t - max_gap;
echo(str("--- Watertightness Analysis ---"));
echo(str("Slice step: ", eff_bend_deg / slices, " deg, Max slice gap: ", max_gap, " mm"));
echo(str("Slice thickness: ", slice_t, " mm => Minimum slice overlap: ", min_overlap, " mm"));
assert(min_overlap >= 0.2, 
    str("Slice overlap (", min_overlap, " mm) is less than required 0.2 mm! Increase slice_t or slices."));

// 4. Bambu Lab A1 Mini Bed Size Validation (180 x 180 mm bed):
est_name_w    = len(name) * name_size * 0.82;
est_desig_w   = len(desig) * desig_size * 0.72;
est_plate_len = max(est_name_w, est_desig_w) + 2 * (margin + 3);

max_allowed_len = print_diagonal ? 245 : 175;
echo(str("--- Bed Size Analysis ---"));
echo(str("Estimated Plate Length: ", est_plate_len, " mm (Max allowed: ", max_allowed_len, " mm)"));

assert(est_plate_len <= max_allowed_len,
    str("Plate length (~", round(est_plate_len), " mm) exceeds the ", max_allowed_len, 
        " mm Bambu Lab A1 Mini limit! To fix: reduce name_size/desig_size, split the name, ",
        "or set print_diagonal = true to print along the 245 mm bed diagonal."));

// 5. Hinge Line Positions (accounting for font descenders):
desig_descender = 0.30 * desig_size;
desig_hinge_y   = -desig_descender;

name_descender  = 0.30 * name_size;
name_hinge_y    = desig_size + line_gap - name_descender;

// Small overlap into base plate to avoid degenerate coplanar CGAL boolean faces
eps = 0.05;

// =============================================================================
// 2D Profiles
// =============================================================================

// Upper line: Name text (translated along Y)
module name2d() {
    translate([0, desig_size + line_gap])
        text(name, size = name_size, font = fnt);
}

// Lower line: Designation text (baseline at Y=0)
module desig2d() {
    text(desig, size = desig_size, font = fnt);
}

// Base plate 2D profile: outline lip around the hull of both text lines
module plate2d() {
    offset(r = 3) offset(delta = margin)
        hull() {
            name2d();
            desig2d();
        }
}

// Inlay tab 2D profile under designation for modular snap-fit assembly
module desig_tab2d() {
    offset(r = 1.5) offset(delta = 1.5)
        hull() {
            desig2d();
        }
}

// =============================================================================
// 3D Geometry Modules
// =============================================================================

// Slanted Name Text (Sliced Curved Bend)
module slanted_name_3d() {
    translate([0, 0, base_t - eps]) {
        for (i = [0 : slices - 1]) {
            ang = i * (eff_bend_deg / slices);
            translate([0, name_hinge_y, 0])
                rotate([ang, 0, 0])
                    translate([0, -name_hinge_y, 0])
                        linear_extrude(slice_t + eps)
                            name2d();
        }
    }
}

// Vertically Raised Name Text
module raised_name_3d() {
    translate([0, 0, base_t])
        linear_extrude(name_h)
            name2d();
}

// Slanted Designation Text (Sliced Curved Bend)
module slanted_desig_3d() {
    translate([0, 0, base_t]) {
        for (i = [0 : slices - 1]) {
            ang = i * (eff_bend_deg / slices);
            translate([0, desig_hinge_y, 0])
                rotate([ang, 0, 0])
                    translate([0, -desig_hinge_y, 0])
                        linear_extrude(slice_t)
                            desig2d();
        }
    }
}

// Part 1: Color Part (Base Plate + Slanted or Raised Name)
module color_part() color(base_color) {
    linear_extrude(base_t) plate2d();
    if (slant_name) {
        slanted_name_3d();
    } else {
        raised_name_3d();
    }
}

// Part 2: White Part (Curved Sliced Designation Text)
module white_part() color(text_color) {
    slanted_desig_3d();
}

// Non-AMS Mode 1: Single Unified Solid for Slicer Layer Pause (M600)
// Base prints in Color 1 (Z=0..base_t). Slicer pauses at base_t.
// User swaps filament to Color 2. Both Name and Designation print in Color 2.
module layer_pause_part() {
    color(base_color) linear_extrude(base_t) plate2d();
    color(text_color) {
        if (slant_name) {
            slanted_name_3d();
        } else {
            raised_name_3d();
        }
        slanted_desig_3d();
    }
}

// Non-AMS Mode 2: Inlay Assembly - Base Plate with Recessed Socket
module assembly_base_part() color(base_color) {
    difference() {
        linear_extrude(base_t) plate2d();
        // Recessed pocket for snap-in designation insert
        translate([0, 0, base_t - inlay_depth])
            linear_extrude(inlay_depth + 1)
                offset(delta = inlay_tol)
                    desig_tab2d();
    }
    if (slant_name) {
        slanted_name_3d();
    } else {
        raised_name_3d();
    }
}

// Non-AMS Mode 2: Inlay Assembly - Standalone Designation Insert
module assembly_insert_part() color(text_color) {
    // Bottom mating tab that fits flush into the base pocket
    linear_extrude(inlay_depth)
        desig_tab2d();
    
    // Slanted curved designation text on top of the mating tab
    translate([0, 0, inlay_depth - eps]) {
        for (i = [0 : slices - 1]) {
            ang = i * (eff_bend_deg / slices);
            translate([0, desig_hinge_y, 0])
                rotate([ang, 0, 0])
                    translate([0, -desig_hinge_y, 0])
                        linear_extrude(slice_t)
                            desig2d();
        }
    }
}

// =============================================================================
// Top-Level Output Assembly
// =============================================================================

module main_assembly() {
    if (part == "all") {
        if (print_mode == "layer_pause") {
            layer_pause_part();
        } else if (print_mode == "inlay_assembly") {
            assembly_base_part();
            translate([0, 0, base_t - inlay_depth]) assembly_insert_part();
        } else {
            color_part();
            white_part();
        }
    } else if (part == "color") {
        color_part();
    } else if (part == "white") {
        white_part();
    } else if (part == "layer_pause") {
        layer_pause_part();
    } else if (part == "assembly_base") {
        assembly_base_part();
    } else if (part == "assembly_insert") {
        assembly_insert_part();
    }
}

// Optional 45-degree rotation for diagonal printing on 180x180mm bed
if (print_diagonal) {
    rotate([0, 0, 45]) main_assembly();
} else {
    main_assembly();
}
