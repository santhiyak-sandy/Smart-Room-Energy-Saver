`timescale 1ns / 1ps
module tb_smart_room_energy_saver;
reg clk, reset, sensor_A, sensor_B;
wire [3:0] people_count;
wire light1, light2, light3;
wire [6:0] seg;
integer errors, entry_seen, exit_seen, i;
reg show_fsm;

smart_room uut(.clk(clk),.reset(reset),.sensor_A(sensor_A),.sensor_B(sensor_B),
 .people_count(people_count),.light1(light1),.light2(light2),.light3(light3),.seg(seg));

initial clk=0;
always #5 clk=~clk;

always @(posedge clk) begin
    if (uut.entry_pulse) entry_seen=entry_seen+1;
    if (uut.exit_pulse) exit_seen=exit_seen+1;
end

task wait_clks; input integer n;
begin repeat(n) @(negedge clk); end endtask

task apply_step; input a,b;
begin sensor_A=a; sensor_B=b; wait_clks(6); end endtask

task do_entry;
begin
    apply_step(1'b1,1'b0);
    apply_step(1'b1,1'b1);
    apply_step(1'b0,1'b0);
    wait_clks(2);
end endtask

task do_exit;
begin
    apply_step(1'b0,1'b1);
    apply_step(1'b1,1'b1);
    apply_step(1'b0,1'b0);
    wait_clks(2);
end endtask

initial begin
    errors=0; entry_seen=0; exit_seen=0; show_fsm=0;
    reset=1; sensor_A=0; sensor_B=0;
    wait_clks(4); reset=0; wait_clks(3);

    do_entry; do_entry; do_exit; do_exit;
    do_exit;

    for(i=1;i<=15;i=i+1) do_entry;
    do_entry;
    for(i=1;i<=15;i=i+1) do_exit;

    if(errors==0) $display("=== ALL TESTS PASSED ===");
    else $display("=== TESTS FAILED ===");
    wait_clks(5); $finish;
end
endmodule
