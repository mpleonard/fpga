`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Martin Pang Leonard
// 
// Create Date: 03/03/2017 10:53:04 AM
// Design Name: 
// Module Name: cs_mux_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cs_mux_tb;

    reg         clock;
    wire [4:0]  cfg;
    wire        oen0, oen1;
    wire [2:0]  mux0, mux1;

    reg [5:0]   n;

    cs_mux cs (
        .aclk(clock),
        .cfg(cfg),
        .oen0(oen0),
        .oen1(oen1),
        .mux0(mux0),
        .mux1(mux1)
    );

    initial begin
        clock = 0;
        n = 6'b0;
        forever #1 clock = ~clock;
    end

    always @(posedge clock) begin
        #1;
        n <= n + 1;
    end
    
    assign cfg = n[4:0];

    always @(negedge clock) begin
        if (n[5] === 1) begin
            $display("Test complete");
            $stop;
        end
        if (oen0 === 0) begin
            if (cfg[4:3] !== 2'b10)
                $display("Error: 0 enabled for %b", cfg[4:3]);
            if (mux0 !== cfg[2:0])
                $display("Error: mux0 = %b and cfg = %b", mux0[2:0], cfg[2:0]);
        end
        if (oen1 === 0) begin
            if (cfg[4:3] !== 2'b11)
                $display("Error: 1 enabled for %b", cfg[4:3]);
            if (mux1 !== cfg[2:0])
                $display("Error: mux1 = %b and cfg = %b", mux1[2:0], cfg[2:0]);
        end
    end

endmodule
