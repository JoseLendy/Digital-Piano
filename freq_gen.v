module freq_gen (
    input        clk,
    input        rst,
    input  [4:0] note_id,
    input        play_en,
    output reg   buzzer
);

    reg [31:0] threshold;
    reg [31:0] cnt;

    always @(*) begin
        case (note_id)
            5'd0:  threshold = 32'd191113;  
            5'd1:  threshold = 32'd180388;  
            5'd2:  threshold = 32'd170265;  
            5'd3:  threshold = 32'd160705;  
            5'd4:  threshold = 32'd151686;  
            5'd5:  threshold = 32'd143172;  
            5'd6:  threshold = 32'd135137; 
            5'd7:  threshold = 32'd127551;  
            5'd8:  threshold = 32'd120395; 
            5'd9:  threshold = 32'd113636; 
            5'd10: threshold = 32'd107259; 
            5'd11: threshold = 32'd101239; 
            5'd12: threshold = 32'd95557;  
            5'd13: threshold = 32'd90194;  
            5'd14: threshold = 32'd85132;  
            5'd15: threshold = 32'd80353;  
            5'd16: threshold = 32'd75843;  
            5'd17: threshold = 32'd71586;  
            5'd18: threshold = 32'd67568;  
            5'd19: threshold = 32'd63776; 
            default: threshold = 32'd191113;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt    <= 0;
            buzzer <= 0;
        end else if (!play_en) begin
            cnt    <= 0;
            buzzer <= 0;
        end else begin
            if (cnt >= threshold - 1) begin
                cnt    <= 0;
                buzzer <= ~buzzer;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

endmodule