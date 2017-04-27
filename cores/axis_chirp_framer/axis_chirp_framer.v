`timescale 1 ns / 1 ps;

//////////////////////////////////////////////////////////////////////////////////
// Company: UCL
// Engineer: Martin Pang Leonard
// 
// Create Date: 03/17/2017 04:20:06 PM
// Design Name: fmcw
// Module Name: axis_fmcw_window
// Project Name: fmcw
// Target Devices: RedPitaya, zynq-z010
// Tool Versions: Vivado 2016.4
// Description: Frames and zero-pads the DDC'd data for the Xilinx FFT core.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module axis_chirp_framer #
(
    parameter integer AXIS_TDATA_WIDTH = 32,
    parameter integer INDEX_WIDTH = 16
)
(
    // System signals
    input wire                          aclk,
    input wire                          aresetn,
    
    // Configuration: Transform window size
    //  size = 1 << cfg_data[3:0] 
    input wire [3:0]                    cfg_nfft,

    output wire                         err_nsmall,

    // Ramp signal
    input wire                          ramp,

    // AXIS Slave
    input wire [AXIS_TDATA_WIDTH-1:0]   s_axis_tdata,
    input wire                          s_axis_tvalid,
    output wire                         s_axis_tready,

    // AXIS Master
    output wire [AXIS_TDATA_WIDTH-1:0]  m_axis_tdata,
    output wire [INDEX_WIDTH-1:0]       m_axis_tuser,
    output wire                         m_axis_tvalid,
    output wire                         m_axis_tlast,
    input wire                          m_axis_tready
);

reg [INDEX_WIDTH-1:0] index;
reg zeroing;
reg en;

wire [11:0] index_last;
wire tlast;

assign index_last = (1 << cfg_nfft) - 1;
assign tlast = (index == index_last) ? 1 : 0;

assign s_axis_tready = (zeroing) ? 0 : m_axis_tready;

assign m_axis_tdata = (zeroing) ? {(AXIS_TDATA_WIDTH){1'b0}} : s_axis_tdata;
assign m_axis_tvalid = (zeroing) ? 1 : s_axis_tvalid & en;
assign m_axis_tlast = tlast;
assign m_axis_tuser = index;

assign err_nsmall = tlast & ~zeroing;

always @(posedge aclk) begin
    if (~aresetn) begin
        index <= {(INDEX_WIDTH){1'b0}};
        zeroing <= 0;
        en <= 0;
    end
    else begin
        if (en) begin
            if (m_axis_tready & m_axis_tvalid) begin
                if (tlast) begin
                    index <= {(INDEX_WIDTH){1'b0}};
                    zeroing <= 0;
                end
                else
                    index <= index + 1;
            end
        end
    end
end

always @(posedge ramp) begin
    if (~en)
        en = 1;
    else
        zeroing = 1;
end

endmodule
