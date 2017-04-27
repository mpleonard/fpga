`timescale 1 ns / 1 ps

module axis_fft_halve #
(
    AXIS_TDATA_WIDTH = 32,
    AXIS_TUSER_WIDTH = 16
)
(
    input aclk,
    input aresetn,

    input [3:0] cfg_nfft,

    input [AXIS_TDATA_WIDTH-1:0] s_axis_tdata,
    input [AXIS_TUSER_WIDTH-1:0] s_axis_tuser,
    input s_axis_tvalid,
    output s_axis_tready,

    output [AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
    output [AXIS_TUSER_WIDTH-1:0] m_axis_tuser,
    output m_axis_tvalid,
    input m_axis_tready
);

endmodule
