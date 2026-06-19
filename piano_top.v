module piano_top (
    input  clk,
    output [3:0] mat_row,
    input  [3:0] mat_col,
    output buzzer,
    output seg_clk,
    output seg_clrn,
    output seg_sout,
    output SEG_PEN,
    output LED_IDLE,
    output LED_REC,
    output LED_PLAY
);

    reg [3:0] rst_cnt = 4'hF;
    wire rst = (rst_cnt != 4'd0);
    always @(posedge clk)
        if (rst_cnt != 4'd0) rst_cnt <= rst_cnt - 1;

    wire [4:0] note_id;
    wire       key_valid, key_release;
    wire       btn_record, btn_play, btn_stop;

    matrix_scan u_matrix (
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

    wire        wr_en;
    wire [7:0]  wr_addr, rd_addr;
    wire [4:0]  wr_note, rd_note;
    wire [15:0] wr_dur,  rd_dur;

    wire [4:0] play_note;
    wire       play_en;
    wire [1:0] state_out;

    fsm_ctrl u_fsm (
        .clk        (clk),
        .rst        (rst),
        .btn_record (btn_record),
        .btn_play   (btn_play),
        .btn_stop   (btn_stop),
        .note_id    (note_id),
        .key_valid  (key_valid),
        .key_release(key_release),
        .rd_note    (rd_note),
        .rd_dur     (rd_dur),
        .play_note  (play_note),
        .play_en    (play_en),
        .wr_en      (wr_en),
        .wr_addr    (wr_addr),
        .wr_note    (wr_note),
        .wr_dur     (wr_dur),
        .rd_addr    (rd_addr),
        .state_out  (state_out)
    );

    note_ram u_ram (
        .clk     (clk),
        .wr_en   (wr_en),
        .wr_addr (wr_addr),
        .wr_note (wr_note),
        .wr_dur  (wr_dur),
        .rd_addr (rd_addr),
        .rd_note (rd_note),
        .rd_dur  (rd_dur)
    );

    freq_gen u_freq (
        .clk     (clk),
        .rst     (rst),
        .note_id (play_note),
        .play_en (play_en),
        .buzzer  (buzzer)
    );

    seg7_driver u_seg (
        .clk      (clk),
        .rst      (rst),
        .state    (state_out),
        .note_id  (play_note),
        .seg_clk  (seg_clk),
        .seg_clrn (seg_clrn),
        .seg_sout (seg_sout),
        .SEG_PEN  (SEG_PEN)
    );

    assign LED_IDLE = (state_out == 2'd0);
    assign LED_REC  = (state_out == 2'd1);
    assign LED_PLAY = (state_out == 2'd2);

endmodule