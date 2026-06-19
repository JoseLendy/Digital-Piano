# ============================================================
# piano_constraints.xdc - FINAL VERIFIED
# Buzzer: AF25 (from course docs)
# Matrix: BTN_X=outputs, BTN_Y=inputs (verified from lab7/lab8)
# ============================================================

# ── Main Clock (100 MHz) ─────────────────────────────────────
set_property PACKAGE_PIN AC18 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports clk]
create_clock -period 10.000 -name clk [get_ports "clk"]

# ── 4x4 Button Matrix ────────────────────────────────────────
set_property PACKAGE_PIN V17 [get_ports {mat_row[0]}]
set_property PACKAGE_PIN W18 [get_ports {mat_row[1]}]
set_property PACKAGE_PIN W19 [get_ports {mat_row[2]}]
set_property PACKAGE_PIN W15 [get_ports {mat_row[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mat_row[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mat_row[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mat_row[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mat_row[3]}]

set_property PACKAGE_PIN V18 [get_ports {mat_col[0]}]
set_property PACKAGE_PIN V19 [get_ports {mat_col[1]}]
set_property PACKAGE_PIN V14 [get_ports {mat_col[2]}]
set_property PACKAGE_PIN W14 [get_ports {mat_col[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mat_col[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mat_col[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mat_col[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {mat_col[3]}]
set_property PULLUP true [get_ports {mat_col[0]}]
set_property PULLUP true [get_ports {mat_col[1]}]
set_property PULLUP true [get_ports {mat_col[2]}]
set_property PULLUP true [get_ports {mat_col[3]}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets mat_col*]

# ── Buzzer ───────────────────────────────────────────────────
set_property PACKAGE_PIN AF25 [get_ports buzzer]
set_property IOSTANDARD LVCMOS33 [get_ports buzzer]

# ── 7-Segment Display ────────────────────────────────────────
set_property PACKAGE_PIN M24 [get_ports seg_clk]
set_property IOSTANDARD LVCMOS33 [get_ports seg_clk]
set_property PACKAGE_PIN M20 [get_ports seg_clrn]
set_property IOSTANDARD LVCMOS33 [get_ports seg_clrn]
set_property PACKAGE_PIN L24 [get_ports seg_sout]
set_property IOSTANDARD LVCMOS33 [get_ports seg_sout]
set_property PACKAGE_PIN R18 [get_ports SEG_PEN]
set_property IOSTANDARD LVCMOS33 [get_ports SEG_PEN]

# ── LED State Indicators ──────────────────────────────────────
set_property PACKAGE_PIN AF24 [get_ports LED_IDLE]
set_property IOSTANDARD LVCMOS33 [get_ports LED_IDLE]
set_property PACKAGE_PIN AE21 [get_ports LED_REC]
set_property IOSTANDARD LVCMOS33 [get_ports LED_REC]
set_property PACKAGE_PIN Y22  [get_ports LED_PLAY]
set_property IOSTANDARD LVCMOS33 [get_ports LED_PLAY]