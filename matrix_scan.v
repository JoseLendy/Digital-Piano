module matrix_scan (
    input        clk,
    input        rst,
    output reg [3:0] row,
    input      [3:0] col,
    output reg [4:0] note_id,
    output reg       key_valid,
    output reg       key_release,
    output reg       btn_record,
    output reg       btn_play,
    output reg       btn_stop
);

    reg [16:0] scan_cnt;
    reg [1:0]  row_idx;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scan_cnt <= 0;
            row_idx  <= 0;
        end else begin
            if (scan_cnt == 17'd99999) begin
                scan_cnt <= 0;
                row_idx  <= row_idx + 1;
            end else
                scan_cnt <= scan_cnt + 1;
        end
    end

    always @(*) begin
        case (row_idx)
            2'd0: row = 4'b1110;
            2'd1: row = 4'b1101;
            2'd2: row = 4'b1011;
            2'd3: row = 4'b0111;
        endcase
    end

    reg [3:0] col_stable  [0:3];
    reg [3:0] col_sample  [0:3];
    reg [3:0] debounce_cnt[0:3]; 

    localparam DEBOUNCE_N = 4'd15;
    localparam SAMPLE_T   = 17'd99000;

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                col_stable[i]   <= 4'hF;
                col_sample[i]   <= 4'hF;
                debounce_cnt[i] <= 0;
            end
            note_id     <= 0;
            key_valid   <= 0;
            key_release <= 0;
            btn_record  <= 0;
            btn_play    <= 0;
            btn_stop    <= 0;
        end else begin
            key_valid   <= 0;
            key_release <= 0;
            btn_record  <= 0;
            btn_play    <= 0;
            btn_stop    <= 0;

            if (scan_cnt == SAMPLE_T) begin
                if (col == col_sample[row_idx]) begin
                    if (debounce_cnt[row_idx] < DEBOUNCE_N)
                        debounce_cnt[row_idx] <= debounce_cnt[row_idx] + 1;
                end else begin
                    col_sample[row_idx]   <= col;
                    debounce_cnt[row_idx] <= 1;
                end

                if (debounce_cnt[row_idx] == DEBOUNCE_N &&
                    col == col_sample[row_idx] &&
                    col != col_stable[row_idx]) begin

                    col_stable[row_idx] <= col;

                    if (row_idx != 2'd3) begin
                        if (col != 4'hF) begin
                            key_valid   <= 1;
                            key_release <= 0;
                            case ({row_idx, col})
                                {2'd0, 4'b1110}: note_id <= 5'd0;
                                {2'd0, 4'b1101}: note_id <= 5'd2;
                                {2'd0, 4'b1011}: note_id <= 5'd4;
                                {2'd0, 4'b0111}: note_id <= 5'd5;
                                {2'd1, 4'b1110}: note_id <= 5'd7;
                                {2'd1, 4'b1101}: note_id <= 5'd9;
                                {2'd1, 4'b1011}: note_id <= 5'd11;
                                {2'd1, 4'b0111}: note_id <= 5'd12;
                                {2'd2, 4'b1110}: note_id <= 5'd14;
                                {2'd2, 4'b1101}: note_id <= 5'd16;
                                {2'd2, 4'b1011}: note_id <= 5'd17;
                                {2'd2, 4'b0111}: note_id <= 5'd19;
                                default:         note_id <= 5'd0;
                            endcase
                        end else begin
                            key_valid   <= 1;
                            key_release <= 1;
                        end
                    end else begin
                        if (~col[0]) btn_record <= 1;
                        if (~col[1]) btn_play   <= 1;
                        if (~col[2]) btn_stop   <= 1;
                    end
                end
            end
        end
    end

endmodule