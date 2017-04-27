`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Martin Pang Leonard
// 
// Create Date: 03/03/2017 10:46:10 AM
// Design Name: 
// Module Name: cs_mux
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

module cs_mux
(
    input   wire        aclk,
    input   wire [4:0]  cfg,

    output  wire        oen0,
    output  wire        oen1,
    output  wire [2:0]  mux0,
    output  wire [2:0]  mux1
);

    reg [2:0] mux0_reg, mux1_reg;
    reg [1:0] oen_reg;

    assign {mux1, mux0} = {mux1_reg, mux0_reg};
    assign {oen1, oen0} = oen_reg;

    always @(posedge aclk) begin
        if (cfg[4] == 1) begin
            if (cfg[3] == 0) begin
                mux0_reg <= cfg[2:0];
                oen_reg <= 2'b10;
            end
            else begin
                mux1_reg <= cfg[2:0];
                oen_reg <= 2'b01;
            end
        end
        else begin
            oen_reg <= 2'b11;
        end
    end

endmodule
