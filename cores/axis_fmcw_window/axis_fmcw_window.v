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

module axis_fmcw_window #
(
    parameter integer AXIS_TDATA_WIDTH = 32,
    parameter integer STS_SN_SIZE = 10
)
(
    // System signals
    input wire                          aclk,
    input wire                          aresetn,
    output wire                         err_nsmall,
    output wire                         err_overskip,
    
    // Configuration: Transform window size, Chirp beginning skip
    //  size = 1 << cfg_data[4:0] 
    //  skip = cfg_data[7:5]
    input wire [7:0]                    cfg_data,

    // Status register: 10-bit seqno of current ramp
    output wire [STS_SN_SIZE-1:0]                  sts_data,
    
    // Ramp signal
    input wire                          ramp,

    // AXIS Slave
    input wire [AXIS_TDATA_WIDTH-1:0]   s_axis_data_tdata,
    input wire                          s_axis_data_tvalid,
    output wire                         s_axis_data_tready,

    // AXIS Master
    output wire [AXIS_TDATA_WIDTH-1:0]  m_axis_data_tdata,
    output wire                         m_axis_data_tvalid,
    output wire                         m_axis_data_tlast,
    input wire                          m_axis_data_tready
);

reg [1:0] state, state_next;
localparam ZERO = 2'd0, NORMAL = 2'd1, WAIT = 2'd2;

reg [AXIS_TDATA_WIDTH-1:0] in_data, out_data;
reg [11:0] in_seqno, out_seqno;
reg out_valid;

reg en;
reg err_nsmall_reg;
reg err_overskip_reg;
reg [11:0] max;
reg [7:0] skip;
reg [STS_SN_SIZE-1:0] ramp_seqno;

assign err_nsmall = err_nsmall_reg;
assign err_overskip = err_overskip_reg;

assign s_axis_data_tready = 1;

assign m_axis_data_tdata = out_data;
assign m_axis_data_tvalid = (out_valid & en);
assign m_axis_data_tlast = (out_seqno == max) ? out_valid : 0;

assign sts_data = {6'd0, ramp_seqno};

// cfg_data latch
always @(cfg_data) begin
    max <= (1 << cfg_data[4:0]) - 1;
    skip <= cfg_data[7:5];
end

// Sequential logic
always @(posedge aclk) begin
    if (~aresetn) begin
        //system
        en <= 0;
        err_nsmall_reg <= 0;
        err_overskip_reg <= 0;
        state <= WAIT;
        state_next <= WAIT;

        //in
        in_data <= {(AXIS_TDATA_WIDTH){1'b0}};
        in_seqno <= 12'b0;

        //out
        out_data <= {(AXIS_TDATA_WIDTH){1'b0}};
        out_seqno <= 12'b0;
        out_valid <= 0;

        ramp_seqno <= 0;
    end
    else if (en) begin
        // Update reg
        state <= state_next;

        if (s_axis_data_tvalid) begin
            in_data <= s_axis_data_tdata;
            if (in_seqno < max) begin
                in_seqno <= in_seqno + 1;
            end
            else begin
                in_seqno <= 0;
                err_nsmall_reg <= 1;
            end
        end

        if (m_axis_data_tready && m_axis_data_tvalid) begin
            if (out_seqno < max) begin
                out_seqno <= out_seqno + 1;
            end
            else begin
                out_seqno <= 0;
                state_next <= NORMAL;
            end
        end
    end
end

always @(in_data, in_seqno, out_seqno, state) begin
    if (out_seqno < skip || state == ZERO) begin
        out_data <= {(AXIS_TDATA_WIDTH){1'b0}};
        out_valid <= 1;
        if (skip < in_seqno) begin
            skip <= in_seqno;
            err_overskip_reg <= 1;
        end
    end
    else if (out_seqno < in_seqno) begin
        out_data <= in_data;
        out_valid <= 1;
    end
    else begin
        out_valid <= 0;
    end
end

always @(posedge ramp) begin
    if (en) begin
        state_next <= ZERO;
        ramp_seqno <= ramp_seqno + 1;
    end
    else if (state == WAIT) begin
        en <= 1;
        state_next <= NORMAL;
        ramp_seqno <= 0;
    end
    in_seqno <= 0;
end


endmodule
