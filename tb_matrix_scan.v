`timescale 1ns/1ps

module tb_matrix_scan;

    reg        clk, rst;
    wire [3:0] mat_row;
    reg  [3:0] mat_col;
    wire [4:0] note_id;
    wire       key_valid, key_release;
    wire       btn_record, btn_play, btn_stop;

    matrix_scan uut (
        .clk        (clk),
        .rst        (rst),
        .row        (mat_row),
        .col        (mat_col),
        .note_id    (note_id),
        .key_valid  (key_valid),
        .key_release(key_release),
        .btn_record (btn_record),
        .btn_play   (btn_play),
        .btn_stop   (btn_stop)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    localparam HOLD_CYCLES = 7_000_000;

    reg        saw_valid;
    reg  [4:0] last_note;
    reg        saw_record, saw_play, saw_stop;

    task press_note;
        input [1:0] r;
        input [1:0] c;
        integer i;
        reg [3:0] target_row;
        begin
            saw_valid  = 1'b0;
            target_row = ~(4'b0001 << r);
            for (i = 0; i < HOLD_CYCLES; i = i + 1) begin
                @(posedge clk);
                if (mat_row == target_row)
                    mat_col = ~(4'b0001 << c); 
                else
                    mat_col = 4'hF;            
            end
            for (i = 0; i < HOLD_CYCLES; i = i + 1) begin
                @(posedge clk);
                mat_col = 4'hF;
            end
        end
    endtask

    task press_ctrl;
        input [1:0] c;
        integer i;
        begin
            for (i = 0; i < HOLD_CYCLES; i = i + 1) begin
                @(posedge clk);
                if (mat_row == 4'b0111)
                    mat_col = ~(4'b0001 << c);
                else
                    mat_col = 4'hF;
            end
            for (i = 0; i < HOLD_CYCLES; i = i + 1) begin
                @(posedge clk);
                mat_col = 4'hF;
            end
        end
    endtask

    function [39:0] note_name;
        input [4:0] id;
        case (id)
            5'd0:  note_name = "C4   ";
            5'd2:  note_name = "D4   ";
            5'd4:  note_name = "E4   ";
            5'd5:  note_name = "F4   ";
            5'd7:  note_name = "G4   ";
            5'd9:  note_name = "A4   ";
            5'd11: note_name = "B4   ";
            5'd12: note_name = "C5   ";
            5'd14: note_name = "D5   ";
            5'd16: note_name = "E5   ";
            5'd17: note_name = "F5   ";
            5'd19: note_name = "G5   ";
            default: note_name = "?    ";
        endcase
    endfunction

    always @(posedge clk) begin
        if (key_valid && !key_release) begin
            saw_valid <= 1'b1;
            last_note <= note_id;
            $display("[%0t ns] KEY PRESS   note_id=%0d (%s)  row=%b",
                     $time/1000, note_id, note_name(note_id), mat_row);
        end
        if (key_valid && key_release)
            $display("[%0t ns] KEY RELEASE", $time/1000);
        if (btn_record) begin
            saw_record <= 1'b1;
            $display("[%0t ns] BTN_RECORD pulse", $time/1000);
        end
        if (btn_play) begin
            saw_play <= 1'b1;
            $display("[%0t ns] BTN_PLAY pulse", $time/1000);
        end
        if (btn_stop) begin
            saw_stop <= 1'b1;
            $display("[%0t ns] BTN_STOP pulse", $time/1000);
        end
    end

    integer pass_count;

    task check_note;
        input [4:0] expect_id;
        input [63:0] label;
        begin
            $display("   Result: saw_valid=%0d  note=%0d  (expect %0d)",
                     saw_valid, last_note, expect_id);
            if (saw_valid && last_note == expect_id) begin
                $display("   [PASS] %s", label);
                pass_count = pass_count + 1;
            end else
                $display("   [FAIL] %s", label);
        end
    endtask

    initial begin
        pass_count = 0;
        saw_valid  = 0;  last_note  = 0;
        saw_record = 0;  saw_play   = 0;  saw_stop = 0;
        rst        = 1;
        mat_col    = 4'hF;           
        repeat(20) @(posedge clk);
        rst = 0;
        repeat(20) @(posedge clk);

        $display("\n=== TEST 1: Press C4 (Row0 Col0) => expect note_id=0 ===");
        press_note(0, 0);
        check_note(5'd0, "C4");

        $display("\n=== TEST 2: Press A4 (Row1 Col1) => expect note_id=9 ===");
        press_note(1, 1);
        check_note(5'd9, "A4");

        $display("\n=== TEST 3: Press G5 (Row2 Col3) => expect note_id=19 ===");
        press_note(2, 3);
        check_note(5'd19, "G5");

        $display("\n=== TEST 4: Control row - RECORD button ===");
        saw_record = 0;
        press_ctrl(0);
        if (saw_record) begin
            $display("   [PASS] BTN_RECORD asserted"); pass_count = pass_count + 1;
        end else
            $display("   [FAIL] BTN_RECORD never asserted");

        $display("\n=== TEST 5: Control row - PLAY button ===");
        saw_play = 0;
        press_ctrl(1);
        if (saw_play) begin
            $display("   [PASS] BTN_PLAY asserted"); pass_count = pass_count + 1;
        end else
            $display("   [FAIL] BTN_PLAY never asserted");

        $display("\n=== TEST 6: Control row - STOP button ===");
        saw_stop = 0;
        press_ctrl(2);
        if (saw_stop) begin
            $display("   [PASS] BTN_STOP asserted"); pass_count = pass_count + 1;
        end else
            $display("   [FAIL] BTN_STOP never asserted");

        $display("\n=== MATRIX SCAN TESTS DONE: %0d/6 passed ===", pass_count);
        $finish;
    end

endmodule