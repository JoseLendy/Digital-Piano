module seg7_driver (
    input        clk,
    input        rst,
    input  [1:0] state,
    input  [4:0] note_id,
    output       seg_clk,
    output       seg_clrn,
    output       seg_sout,
    output       SEG_PEN
);
    reg [31:0] div_cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) div_cnt <= 32'b0;
        else     div_cnt <= div_cnt + 32'b1;
    end

    wire start_sig = div_cnt[20];   
    wire flash_sig = div_cnt[25];  

    reg [3:0] note_hex;
    always @(*) begin
        case (note_id)
            5'd0, 5'd12: note_hex = 4'hC;
            5'd2, 5'd14: note_hex = 4'hD;
            5'd4, 5'd16: note_hex = 4'hE;
            5'd5, 5'd17: note_hex = 4'hF;
            5'd7, 5'd19: note_hex = 4'h6;
            5'd9:        note_hex = 4'hA;
            5'd11:       note_hex = 4'hB;
            default:     note_hex = 4'h0;
        endcase
    end

    wire [3:0] oct_hex = (note_id >= 5'd12) ? 4'd5 : 4'd4;

    wire is_sharp = (note_id == 5'd1  || note_id == 5'd3  ||
                     note_id == 5'd6  || note_id == 5'd8  ||
                     note_id == 5'd10 || note_id == 5'd13 ||
                     note_id == 5'd15 || note_id == 5'd18);

    reg [3:0] mode_h, mode_l;
    always @(*) begin
        case (state)
            2'd0: begin mode_h = 4'hD; mode_l = 4'hE; end 
            2'd1: begin mode_h = 4'hE; mode_l = 4'hC; end 
            2'd2: begin mode_h = 4'hA; mode_l = 4'hB; end
            default: begin mode_h = 4'h0; mode_l = 4'h0; end
        endcase
    end

    wire [31:0] hexs   = {16'h0000, mode_h, mode_l, oct_hex, note_hex};
    wire [7:0]  points = {6'b0, is_sharp, 1'b0};
    wire [7:0]  les    = 8'h00;

    SSeg_Dev u_sseg (
        .clk     (clk),
        .flash   (flash_sig),
        .Hexs    (hexs),
        .LES     (les),
        .point   (points),
        .rst     (rst),
        .Start   (start_sig), 
        .seg_clk (seg_clk),
        .seg_clrn(seg_clrn),
        .SEG_PEN (SEG_PEN),
        .seg_sout(seg_sout)
    );
endmodule