# FPGA Digital Piano & Music Sequencer

A real-time digital piano and music sequencer implemented in Verilog on a Xilinx Kintex-7 FPGA. Supports live key playing, melody recording to on-chip RAM, and timed sequenced playback.

Built as a solo final project for the Digital Logic Design (数字逻辑设计) course at Zhejiang University.

---

## Features

- **Live piano mode** — Play notes in real time using a 4×4 matrix keypad (two octaves: C4–G5, 20 notes)
- **Record mode** — Capture note + duration pairs into on-chip RAM, including rests between notes
- **Playback mode** — Replay recorded melody with accurate timing via a dedicated FSM
- **Seven-segment display** — Shows current mode and active note
- **LED indicators** — Visual feedback for FSM state
- **Piezo buzzer output** — Square-wave tone generation at correct frequencies

---

## Hardware

| Component | Details |
|-----------|---------|
| FPGA Board | Sword Kintex-7 (`xc7k160tffg676-2L`) |
| Clock | 100 MHz onboard oscillator |
| Keypad | 4×4 matrix (rows: V17/W18/W19/W15, cols: V18/V19/V14/W14 with PULLUP) |
| Buzzer | Piezo, pin AF25 |
| Display | 8-digit seven-segment via shift register (P2S, pins M24/M20/L24/R18) |
| LEDs | On-board LEDs for state indication |

---

## Architecture

```
matrix_scan.v  ──►  fsm_ctrl.v  ──►  note_ram.v
                        │
                        ├──►  freq_gen.v  ──►  buzzer
                        └──►  seg7_driver.v  ──►  display
```

### Module Summary

| Module | Function |
|--------|----------|
| `matrix_scan.v` | Row-scan keypad driver with debounce (~60 ms window, 15 samples × 4 ms) |
| `freq_gen.v` | Frequency divider; generates square waves for C4–G5 (21 notes + REST) |
| `fsm_ctrl.v` | Main FSM: IDLE → PLAY / RECORD / PLAYBACK states; handles REST marker insertion |
| `note_ram.v` | Dual-port synchronous RAM; 21-bit wide entries `{note[4:0], duration[15:0]}` |
| `seg7_driver.v` | 7-segment multiplexed driver via P2S shift register |
| `piano_top.v` | Top-level; instantiates and wires all modules |

### RAM Format

Each entry is 21 bits:

```
[20:16]  note[4:0]   — 0–19: C4–G5, 30: REST, 31: SENTINEL (end of sequence)
[15:0]   dur[15:0]   — duration in clock cycles
```

### FSM States (fsm_ctrl.v)

`IDLE → RECORD → WRITE → ADVANCE → (ADVANCE_REST) → IDLE`  
`IDLE → PLAYBACK → READ → SOUND → NEXT → (REST_WAIT) → IDLE`

The `ADVANCE_REST` and `REST_WAIT` states handle inter-note silence gaps that would otherwise be lost.

---

## Known Design Decisions & Bug History

Notable issues resolved during development (useful if you fork/extend this):

- **Frequency threshold doubling** — `freq_gen.v` thresholds must equal `100_000_000 / (2 × freq)` to produce correct pitch. Halved values produce notes one octave too high.
- **Keypad column settling** — Column lines are sampled ~990 µs into each 1 ms row window (not immediately after row assertion) to allow pull-up settling.
- **P2S Start signal** — `seg7_driver.v` must toggle `Start` with a divided clock (`clk_div[20]`), not hardwire it to `1`. Permanent high prevents the shift register latch from firing → all segments show `8`.
- **Double-write bug** — Writing `note` and incrementing `wr_addr` in the same clock cycle caused duplicate RAM entries; resolved by separating into distinct FSM states.
- **REST marker** — Inter-note silence is stored as a REST entry (note = 30) in RAM; a dedicated FSM state handles playback timing for these entries.

---

## File Structure

```
├── piano_top.v          # Top-level
├── matrix_scan.v        # Keypad driver
├── freq_gen.v           # Tone generator
├── fsm_ctrl.v           # Control FSM
├── note_ram.v           # Note storage
├── seg7_driver.v        # Display driver
├── tb_matrix_scan.v     # Testbench: keypad scanner
├── SSeg_Dev.v           # Course-provided: 7-seg device wrapper
├── HexTo8SEG.v          # Course-provided: hex to segment
├── Hex2Seg.v            # Course-provided: hex decoder
├── MyMC14495.v          # Course-provided: segment encoder
└── P2S.edf              # Course-provided: EDIF shift register netlist
```

> **Note:** `P2S.edf` is an EDIF netlist containing IBUF/OBUF IO primitives. It must be used as a top-level-only component; instantiating it as a submodule corrupts signals.

---

## Simulation & Verification

Testbenches verified with Icarus Verilog and Vivado xsim.

To run with Icarus:
```bash
iverilog -o sim tb_matrix_scan.v matrix_scan.v
vvp sim
```

In Vivado Tcl console:
```tcl
restart
run 1000ms
```

---

## Tools

- **Xilinx Vivado** — Synthesis, implementation, bitstream generation
- **Icarus Verilog** — Testbench verification
- **Target device:** `xc7k160tffg676-2L`

---

## Course

数字逻辑设计 (Digital Logic Design), Zhejiang University  
Instructor: 洪奇军  
Solo project with instructor/TA permission
