`timescale 1ns/1ps

module tb_freq_gen;

    reg        clk, rst;
    reg  [4:0] note_id;
    reg        play_en;
    wire       buzzer;

    freq_gen uut (
        .clk     (clk),
        .rst     (rst),
        .note_id (note_id),
        .play_en (play_en),
        .buzzer  (buzzer)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    real t_rise1, t_rise2, half_period_ns, freq_hz;

    task check_note;
        input [4:0]  nid;
        input [31:0] expected_thresh;
        input [63:0] note_label;
        real expected_freq, tolerance;
        begin
            note_id = nid;
            play_en = 1;
            @(posedge buzzer); t_rise1 = $realtime;
            @(posedge buzzer); t_rise2 = $realtime;

            half_period_ns = (t_rise2 - t_rise1);
            freq_hz        = 1_000_000_000.0 / (half_period_ns * 2.0);
            expected_freq  = 100_000_000.0 / (2.0 * expected_thresh);
            tolerance      = expected_freq * 0.01; // 1% tolerance

            $display("   %s : measured %.2f Hz  (expected %.2f Hz)  diff=%.2f Hz",
                note_label, freq_hz, expected_freq,
                (freq_hz > expected_freq) ? freq_hz - expected_freq : expected_freq - freq_hz);

            if ((freq_hz >= expected_freq - tolerance) &&
                (freq_hz <= expected_freq + tolerance))
                $display("   [PASS]");
            else
                $display("   [FAIL] out of 1%% tolerance");

            play_en = 0;
            repeat(1000) @(posedge clk);
        end
    endtask

    initial begin
        rst = 1; play_en = 0; note_id = 0;
        repeat(10) @(posedge clk);
        rst = 0;
        repeat(10) @(posedge clk);

        $display("\n=== FREQ_GEN: Checking note frequencies ===");
        $display("    (Expected = 100MHz / (2 * threshold))");

        check_note(5'd0,  32'd191113, "C4 (261.6Hz)");
        check_note(5'd4,  32'd151685, "E4 (329.6Hz)");
        check_note(5'd7,  32'd127551, "G4 (392.0Hz)");
        check_note(5'd9,  32'd113636, "A4 (440.0Hz)");
        check_note(5'd11, 32'd101224, "B4 (493.9Hz)");
        check_note(5'd12, 32'd95556,  "C5 (523.3Hz)");
        check_note(5'd19, 32'd63776,  "G5 (784.0Hz)");

        $display("\n=== TEST: play_en=0 silences buzzer ===");
        note_id = 5'd0; play_en = 0;
        repeat(500000) @(posedge clk);
        if (buzzer == 0)
            $display("   [PASS] buzzer=0 when play_en=0");
        else
            $display("   [FAIL] buzzer still active");

        $display("\n=== FREQ_GEN TESTS DONE ===");
        $finish;
    end

endmodule
