`timescale 1 ns / 1 ps

//////////////////////////////////////////////////////////////////////////////////
// Company: UCL
// Engineer: Martin Pang Leonard
// 
// Create Date: 03/17/2017 04:20:06 PM
// Design Name: fmcw
// Module Name: axis_fmcw_rti_tb
// Project Name: fmcw
// Target Devices: RedPitaya, zynq-z010
// Tool Versions: Vivado 2016.4
// Description: Averages the frequency bins of the upbeat and downbeat of an
// FMCW triangle IF. (testbench)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module axis_fmcw_rti_tb;

localparam AXIS_TDATA_WIDTH = 24, AXIS_TUSER_WIDTH = 16, STFT_CHANNELS = 3;

reg aclk, aresetn;
reg [19:0] cfg_data;

reg [AXIS_TDATA_WIDTH/2-1:0]  tb_s_tdata;
wire [AXIS_TDATA_WIDTH-1:0]  tb_s_tdata_inv;
reg [11:0] addr;
wire [AXIS_TUSER_WIDTH-1:0]  tb_s_tuser;
reg tb_s_tvalid;
wire tb_s_tlast, tb_s_tready;

wire [AXIS_TDATA_WIDTH-1:0] tb_m_tdata;
wire [AXIS_TDATA_WIDTH/2-1:0] re, im;
assign re = tb_m_tdata[AXIS_TDATA_WIDTH/2-1:0];
assign im = tb_m_tdata[AXIS_TDATA_WIDTH-1:AXIS_TDATA_WIDTH/2];
wire [AXIS_TUSER_WIDTH-1:0] tb_m_tuser;
wire tb_m_tlast, tb_m_tvalid;
reg tb_m_tready;

wire [AXIS_TDATA_WIDTH*STFT_CHANNELS-1:0] tb_m_stft_tdata;
wire tb_m_stft_tlast, tb_m_stft_tvalid;
reg tb_m_stft_tready;

axis_fmcw_rti #(AXIS_TDATA_WIDTH, AXIS_TUSER_WIDTH, STFT_CHANNELS) afr (
    .aclk(aclk),
    .aresetn(aresetn),
    .cfg_data(cfg_data),
    .s_axis_fft_tdata(tb_s_tdata_inv),
    .s_axis_fft_tuser(tb_s_tuser),
    .s_axis_fft_tlast(tb_s_tlast),
    .s_axis_fft_tvalid(tb_s_tvalid),
    .s_axis_fft_tready(tb_s_tready),
    .m_axis_avg_tdata(tb_m_tdata),
    .m_axis_avg_tuser(tb_m_tuser),
    .m_axis_avg_tlast(tb_m_tlast),
    .m_axis_avg_tvalid(tb_m_tvalid),
    .m_axis_avg_tready(tb_m_tready),
    .m_axis_stft_tdata(tb_m_stft_tdata),
    .m_axis_stft_tlast(tb_m_stft_tlast),
    .m_axis_stft_tvalid(tb_m_stft_tvalid),
    .m_axis_stft_tready(tb_m_stft_tready)
);
localparam NFFT=10, TL=2**NFFT;
genvar i;
generate
for (i = 0; i < NFFT; i=i+1) begin
    assign tb_s_tuser[i] = addr[NFFT-1-i];
end
endgenerate

generate
for (i = 0; i < 12; i=i+1) begin
    assign tb_s_tdata_inv[i] = tb_s_tdata[11-i];
    assign tb_s_tdata_inv[i+12] = tb_s_tdata[11-i];
end
endgenerate

assign tb_s_tuser[15:NFFT] = 4'd0;

assign tb_s_tlast = (addr == TL-1) ? 1 : 0;

initial begin
    // Init
    aclk = 1;
    aresetn = 0;
    cfg_data = {12'd600, 4'd2, 4'd10};
    tb_m_tready = 1;
    tb_m_stft_tready = 1;
    // Test
    #3 aresetn = 1;
    #1000 $finish;
end

always
    #1 aclk = ~aclk;

always @(posedge aclk) begin
    if (~aresetn) begin
        tb_s_tdata <= 0;
        addr <= 12'd0;
        tb_s_tvalid <= 1'b0;
    end
    else begin
        tb_s_tvalid <= 1'b1;
        if (tb_s_tvalid && tb_s_tready) begin
            if (addr != TL-1)
                addr <= addr + 1;
            else
                addr <= 12'd0;
            tb_s_tdata <= tb_s_tdata + 2;
        end
    end
end

endmodule
