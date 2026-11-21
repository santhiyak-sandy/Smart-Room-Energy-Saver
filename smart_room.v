timescale 1ns / 1ps
module sr_input_sync(input wire clk, reset, async_in, output wire sync_out);
    reg ff1, ff2;
    always @(posedge clk) begin
        if (reset) begin ff1 <= 0; ff2 <= 0; end
        else begin ff1 <= async_in; ff2 <= ff1; end
    end
    assign sync_out = ff2;
endmodule

module sr_direction_fsm(
    input wire clk, reset, a, b,
    output wire entry_pulse, exit_pulse,
    output wire [2:0] state_out
);
    parameter [2:0] IDLE=3'd0, A_FIRST=3'd1, B_FIRST=3'd2,
                    ENTRY_DET=3'd3, EXIT_DET=3'd4, WAIT_CLEAR=3'd5;
    reg [2:0] state, next_state;

    always @(posedge clk)
        if (reset) state <= IDLE; else state <= next_state;

    always @(*) begin
        next_state = state;
        case(state)
            IDLE: begin
                if (a && b) next_state=WAIT_CLEAR;
                else if (a) next_state=A_FIRST;
                else if (b) next_state=B_FIRST;
            end
            A_FIRST: begin
                if (b) next_state=ENTRY_DET;
                else if (!a) next_state=IDLE;
            end
            B_FIRST: begin
                if (a) next_state=EXIT_DET;
                else if (!b) next_state=IDLE;
            end
            ENTRY_DET: next_state=WAIT_CLEAR;
            EXIT_DET: next_state=WAIT_CLEAR;
            WAIT_CLEAR: if (!a && !b) next_state=IDLE;
            default: next_state=IDLE;
        endcase
    end
    assign entry_pulse=(state==ENTRY_DET);
    assign exit_pulse=(state==EXIT_DET);
    assign state_out=state;
endmodule

module sr_people_counter(
    input wire clk, reset, entry_pulse, exit_pulse,
    output reg [3:0] count
);
    always @(posedge clk) begin
        if (reset) count<=4'd0;
        else if (entry_pulse) begin
            if (count<4'd15) count<=count+4'd1;
        end else if (exit_pulse) begin
            if (count>4'd0) count<=count-4'd1;
        end
    end
endmodule

module sr_light_controller(
    input wire [3:0] count,
    output reg light1, light2, light3
);
    always @(*) begin
        light1=0; light2=0; light3=0;
        if (count==4'd0) begin end
        else if (count<=4'd3) light1=1;
        else if (count<=4'd6) begin light1=1; light2=1; end
        else begin light1=1; light2=1; light3=1; end
    end
endmodule

module smart_room(
    input wire clk, reset, sensor_A, sensor_B,
    output wire [3:0] people_count,
    output wire light1, light2, light3,
    output wire [6:0] seg
);
    wire a_sync, b_sync, entry_pulse, exit_pulse;
    wire [2:0] fsm_state;

    sr_input_sync u_sync_a(.clk(clk),.reset(reset),.async_in(sensor_A),.sync_out(a_sync));
    sr_input_sync u_sync_b(.clk(clk),.reset(reset),.async_in(sensor_B),.sync_out(b_sync));
    sr_direction_fsm u_fsm(.clk(clk),.reset(reset),.a(a_sync),.b(b_sync),
        .entry_pulse(entry_pulse),.exit_pulse(exit_pulse),.state_out(fsm_state));
    sr_people_counter u_counter(.clk(clk),.reset(reset),
        .entry_pulse(entry_pulse),.exit_pulse(exit_pulse),.count(people_count));
    sr_light_controller u_lights(.count(people_count),.light1(light1),.light2(light2),.light3(light3));
    seven_segment u_seven_segment(.number(people_count),.seg(seg));
endmodule
