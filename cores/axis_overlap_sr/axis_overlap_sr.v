// SISO shift register, with variable depth and overlap.
// AXI4-Stream interface.
`timescale 1 ns / 1 ps

module axis_overlap_sr #
(
    AXIS_TDATA_WIDTH = 16,
    DATA_WIDTH = 16,
    MAX_N_DEPTH = 10
)
(
    input aclk,
    input aresetn,

    input [3:0] cfg_depth,
    input [MAX_N_DEPTH-2:0] cfg_overlap,

    input [AXIS_TDATA_WIDTH-1:0] s_axis_tdata,
    input s_axis_tvalid,
    output s_axis_tready,

    output [AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
    output m_axis_tvalid,
    input m_axis_tready
);

endmodule
