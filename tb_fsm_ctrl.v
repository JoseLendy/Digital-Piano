`timescale 1ns/1ps
module tb_fsm_ctrl;

    reg        clk, rst;
    reg        btn_record, btn_play, btn_stop;
    reg  [4:0] note_id;
    reg        key_valid, key_release;

    reg  [4:0]  sim_note [0:255];
    reg  [15:0] sim_dur  [0:255];
    wire [4:0]  rd_note;
    wire [15:0] rd_dur;
    wire [4:0]  play_note;
    wire        play_en;
    wire        wr_en;
    wire [7:0]  wr_addr, rd_addr;
    wire [4:0]  wr_note;
    wire [15:0] wr_dur;
    wire [1:0]  state_out;

    assign rd_note = sim_note[rd_addr];
    assign rd_dur  = sim_dur [rd_addr];

    always @(posedge clk)
        if (wr_en) begin
            sim_note[wr_addr] <= wr_note;
            sim_dur [wr_addr] <= wr_dur;
            $display("[%0t us] RAM WRITE addr=%0d note=%0d dur=%0d",
                $time/1000000, wr_addr, wr_note, wr_dur);
        end

    fsm_ctrl uut (
        .clk(clk), .rst(rst),
        .btn_record(btn_record), .btn_play(btn_play), .btn_stop(btn_stop),
        .note_id(note_id), .key_valid(key_valid), .key_release(key_release),
        .rd_note(rd_note), .rd_dur(rd_dur),
        .play_note(play_note), .play_en(play_en),
        .wr_en(wr_en), .wr_addr(wr_addr), .wr_note(wr_note), .wr_dur(wr_dur),
        .rd_addr(rd_addr), .state_out(state_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task wait_ms;
        input integer n;
        repeat(n * 100000) @(posedge clk);
    endtask

    task pulse_btn;
        input [2:0] b;
        begin
            @(negedge clk); // change on negedge to avoid setup issues
            if (b==0) btn_record=1;
            if (b==1) btn_play=1;
            if (b==2) btn_stop=1;
            @(posedge clk); @(posedge clk);
            @(negedge clk);
            btn_record=0; btn_play=0; btn_stop=0;
        end
    endtask

    integer i;
    initial begin
        for(i=0;i<256;i=i+1) begin
            sim_note[i]=5'd31; sim_dur[i]=16'd0;
        end
        rst=1; btn_record=0; btn_play=0; btn_stop=0;
        note_id=0; key_valid=0; key_release=0;
        repeat(20) @(posedge clk);
        rst=0;
        repeat(20) @(posedge clk);

        $display("STATE at start: %0d (expect 0)", state_out);

        $display("--- RECORD ---");
        pulse_btn(0);
        repeat(10) @(posedge clk);
        $display("state=%0d wr_ptr/addr=%0d", state_out, wr_addr);

        $display("--- Press C4 ---");
        @(negedge clk);
        note_id=5'd0; key_valid=1; key_release=0;
        @(posedge clk); @(posedge clk);
        @(negedge clk); key_valid=0;

        wait_ms(5);

        @(negedge clk);
        key_valid=1; key_release=1;
        @(posedge clk); @(posedge clk);
        @(negedge clk); key_valid=0; key_release=0;
        repeat(5) @(posedge clk);
        $display("After C4: RAM[0]=note%0d dur%0d  RAM[1]=note%0d dur%0d",
            sim_note[0],sim_dur[0],sim_note[1],sim_dur[1]);

        $display("--- Press A4 ---");
        @(negedge clk);
        note_id=5'd9; key_valid=1; key_release=0;
        @(posedge clk); @(posedge clk);
        @(negedge clk); key_valid=0;

        wait_ms(3);

        @(negedge clk);
        key_valid=1; key_release=1;
        @(posedge clk); @(posedge clk);
        @(negedge clk); key_valid=0; key_release=0;
        repeat(5) @(posedge clk);
        $display("After A4: RAM[0]=note%0d  RAM[1]=note%0d  RAM[2]=note%0d",
            sim_note[0],sim_note[1],sim_note[2]);

        $display("--- STOP ---");
        pulse_btn(2);
        repeat(10) @(posedge clk);
        $display("state=%0d", state_out);
        $display("RAM: [0]=%0d [1]=%0d [2]=%0d [3]=%0d",
            sim_note[0],sim_note[1],sim_note[2],sim_note[3]);
        $display("EXPECT: [0]=0(C4) [1]=9(A4) [2]=31(sentinel)");

        $display("--- PLAY ---");
        pulse_btn(1);
        repeat(100) @(posedge clk);
        $display("state=%0d play_note=%0d play_en=%0d rd_addr=%0d",
            state_out, play_note, play_en, rd_addr);

        wait_ms(20);
        $display("After 20ms: state=%0d (expect 0=IDLE)", state_out);

        $display("=== DONE ===");
        $finish;
    end
endmodule