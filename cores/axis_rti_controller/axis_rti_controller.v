`timescale 1 ns / 1 ps

module axis_rti_controller #
(
    MAG_WIDTH = 16,
    TUSER_WIDTH = 16,
    CORDIC_WIDTH = MAG_WIDTH*2,
    HALF_FFT_WIDTH = 11,
    DOPPLER_WIDTH = 16
)
(
    input                               aclk,
    input                               aresetn,

    input [3:0]                         cfg_bins,

    input [CORDIC_WIDTH-1:0]                          s_axis_tdata,
    input [TUSER_WIDTH-1:0]                           s_axis_tuser,
    input                                             s_axis_tvalid,
    input                                             s_axis_tlast,
    output                                            s_axis_tready,

    output [CORDIC_WIDTH+DOPPLER_WIDTH-1:0]         m_axis_ram_tdata,
    output                                            m_axis_ram_tvalid,
    input                                             m_axis_ram_tready,

    output [MAG_WIDTH-1:0]                            m_axis_md_tdata,
    output                                            m_axis_md_tvalid,
    input                                             m_axis_md_tready
);

assign s_axis_tready = 1;

wire we_u;
wire [HALF_FFT_WIDTH-1:0] addr_u;
wire [CORDIC_WIDTH-1:0] di_u;
reg [CORDIC_WIDTH-1:0] do_u;
(* ram_style = "block" *) reg [CORDIC_WIDTH-1:0] ram_u [(2**HALF_FFT_WIDTH)-1:0];

wire we_d;
wire [HALF_FFT_WIDTH-1:0] addr_d;
wire [CORDIC_WIDTH-1:0] di_d;
reg [CORDIC_WIDTH-1:0] do_d;
(* ram_style = "block" *) reg [CORDIC_WIDTH-1:0] ram_d [(2**HALF_FFT_WIDTH)-1:0];

reg state;

reg [CORDIC_WIDTH*2-1:0] ram_tdata;
reg ram_tvalid;

assign m_axis_ram_tdata = {do_d, do_u};
assign m_axis_ram_tvalid = ram_tvalid;

always @(posedge aclk) begin
    if (we_u) begin
        ram_u[addr_u] <= di_u;
        do_u <= ram_u[addr_u];
    end
end

endmodule
