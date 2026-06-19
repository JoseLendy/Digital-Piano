`timescale 1ns/1ps
module fsm_ctrl (
    input        clk,
    input        rst,
    input        btn_record,
    input        btn_play,
    input        btn_stop,
    input  [4:0] note_id,
    input        key_valid,
    input        key_release,
    input  [4:0]  rd_note,
    input  [15:0] rd_dur,
    output reg [4:0]  play_note,
    output reg        play_en,
    output reg        wr_en,
    output reg [7:0]  wr_addr,
    output reg [4:0]  wr_note,
    output reg [15:0] wr_dur,
    output reg [7:0]  rd_addr,
    output reg [1:0]  state_out
);
    localparam IDLE         = 3'd0;
    localparam RECORD       = 3'd1;
    localparam PLAYBACK     = 3'd2;
    localparam SENTINEL     = 3'd3;
    localparam ADVANCE      = 3'd4;
    localparam ADVANCE_REST = 3'd5;

    localparam REST_MARKER   = 5'd30;
    localparam SENTINEL_NOTE = 5'd31;

    localparam GUARD = 7'd60;

    reg [2:0]  state;
    reg [2:0]  after_stop;
    reg [16:0] ms_cnt;
    reg [15:0] dur_cnt;
    reg        key_playing;
    reg [6:0]  guard_cnt;
    reg        first_note_done;   
    reg [4:0]  pending_note;      

    wire ms_tick    = (ms_cnt == 17'd99999);
    wire guard_done = (guard_cnt >= GUARD);

    always @(posedge clk or posedge rst)
        if (rst) ms_cnt <= 0;
        else     ms_cnt <= ms_tick ? 0 : ms_cnt + 1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state           <= IDLE;
            after_stop      <= IDLE;
            play_note       <= 0;
            play_en         <= 0;
            wr_en           <= 0;
            wr_addr         <= 0;
            wr_note         <= 0;
            wr_dur          <= 0;
            rd_addr         <= 0;
            dur_cnt         <= 0;
            state_out       <= 2'd0;
            key_playing     <= 0;
            guard_cnt       <= GUARD;
            first_note_done <= 0;
            pending_note    <= 0;
        end else begin
            wr_en <= 0;

            if (key_playing && !guard_done && ms_tick)
                guard_cnt <= guard_cnt + 1;

            case (state)

                IDLE: begin
                    state_out <= 2'd0;
                    if (key_valid && !key_release && !key_playing) begin
                        play_note   <= note_id;
                        play_en     <= 1;
                        key_playing <= 1;
                        guard_cnt   <= 0;
                    end else if (key_valid && key_release && guard_done) begin
                        play_en     <= 0;
                        key_playing <= 0;
                        guard_cnt   <= GUARD;
                    end
                    if (btn_record) begin
                        state           <= RECORD;
                        wr_addr         <= 0;
                        play_en         <= 0;
                        dur_cnt         <= 0;
                        key_playing     <= 0;
                        guard_cnt       <= GUARD;
                        first_note_done <= 0;
                    end
                    if (btn_play) begin
                        state       <= PLAYBACK;
                        rd_addr     <= 0;
                        dur_cnt     <= 0;
                        play_en     <= 0;
                        key_playing <= 0;
                        guard_cnt   <= GUARD;
                    end
                end

                RECORD: begin
                    state_out <= 2'd1;
                    if (btn_stop || btn_play) begin
                        wr_en       <= 1;
                        wr_note     <= SENTINEL_NOTE;
                        wr_dur      <= 16'd0;
                        after_stop  <= btn_play ? PLAYBACK : IDLE;
                        state       <= SENTINEL;
                        play_en     <= 0;
                        key_playing <= 0;
                        guard_cnt   <= GUARD;
                    end else if (key_valid && !key_release && !key_playing) begin
                        if (first_note_done) begin
                            wr_en        <= 1;
                            wr_note      <= REST_MARKER;
                            wr_dur       <= dur_cnt;
                            pending_note <= note_id;
                            state        <= ADVANCE_REST;
                            guard_cnt    <= 0;
                        end else begin
                            play_note   <= note_id;
                            play_en     <= 1;
                            dur_cnt     <= 0;
                            key_playing <= 1;
                            guard_cnt   <= 0;
                        end
                    end else if (key_valid && key_release && guard_done) begin
                        wr_en           <= 1;
                        wr_note         <= play_note;
                        wr_dur          <= dur_cnt;
                        play_en         <= 0;
                        dur_cnt         <= 0;
                        key_playing     <= 0;
                        first_note_done <= 1;
                        guard_cnt       <= GUARD;
                        state           <= ADVANCE;
                    end else if (ms_tick) begin
                        if (dur_cnt < 16'hFFFE)
                            dur_cnt <= dur_cnt + 1;
                    end
                end

                ADVANCE: begin
                    state_out <= 2'd1;
                    wr_en     <= 0;
                    wr_addr   <= wr_addr + 1;
                    state     <= RECORD;
                end

                ADVANCE_REST: begin
                    state_out   <= 2'd1;
                    wr_en       <= 0;
                    wr_addr     <= wr_addr + 1;
                    play_note   <= pending_note;
                    play_en     <= 1;
                    dur_cnt     <= 0;
                    key_playing <= 1;
                    state       <= RECORD;
                end

                SENTINEL: begin
                    state_out <= 2'd1;
                    if (after_stop == PLAYBACK) begin
                        state   <= PLAYBACK;
                        rd_addr <= 0;
                        dur_cnt <= 0;
                    end else
                        state <= IDLE;
                end

                PLAYBACK: begin
                    state_out <= 2'd2;
                    if (btn_stop || btn_record) begin
                        state   <= IDLE;
                        play_en <= 0;
                        rd_addr <= 0;
                        dur_cnt <= 0;
                    end else if (rd_note == SENTINEL_NOTE) begin
                        state   <= IDLE;
                        play_en <= 0;
                        rd_addr <= 0;
                    end else if (rd_note == REST_MARKER) begin
                        play_en <= 0;
                        if (ms_tick) begin
                            if (dur_cnt == 0)
                                dur_cnt <= rd_dur;
                            else begin
                                dur_cnt <= dur_cnt - 1;
                                if (dur_cnt == 1) begin
                                    rd_addr <= rd_addr + 1;
                                    dur_cnt <= 0;
                                end
                            end
                        end
                    end else begin
                        play_note <= rd_note;
                        play_en   <= 1;
                        if (ms_tick) begin
                            if (dur_cnt == 0)
                                dur_cnt <= rd_dur;
                            else begin
                                dur_cnt <= dur_cnt - 1;
                                if (dur_cnt == 1) begin
                                    play_en <= 0;
                                    rd_addr <= rd_addr + 1;
                                    dur_cnt <= 0;
                                end
                            end
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule