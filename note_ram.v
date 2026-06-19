module note_ram (
    input        clk,
    input        wr_en,
    input  [7:0] wr_addr,
    input  [4:0] wr_note,
    input [15:0] wr_dur,
    input  [7:0] rd_addr,
    output reg [4:0]  rd_note,
    output reg [15:0] rd_dur
);
    reg [20:0] mem [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = {5'd31, 16'd0};
    end

    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= {wr_note, wr_dur};
        rd_note <= mem[rd_addr][20:16];
        rd_dur  <= mem[rd_addr][15:0];
    end

endmodule