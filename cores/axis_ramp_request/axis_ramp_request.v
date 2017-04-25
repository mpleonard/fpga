`timescale 1 ns / 1 ps;

module axis_ramp_request #
(
    parameter integer COUNTER_WIDTH = 18
)
(
    // System signals
    input wire          aclk,
    input wire          aresetn,

    // Config
    input wire [COUNTER_WIDTH-1:0]   cfg,

    // 1 wire (internal use)
    output wire         ramp_rq,

    // Master AXIS (red_pitaya_dac)
    output wire [15:0]  m_axis_tdata,
    output wire         m_axis_tvalid,
    input wire          m_axis_tready
);

reg dout, dout_next;
reg [COUNTER_WIDTH-1:0] counter, counter_next;
wire [COUNTER_WIDTH-1:0] cfg_half;
assign cfg_half = cfg >> 1;

assign ramp_rq = dout;

assign m_axis_tdata = (dout) ? 16'd8191 : 16'd0;
assign m_axis_tvalid = 1;

always @(posedge aclk) begin
    if (~aresetn) begin
        dout <= 1'b0;
        counter <= {(COUNTER_WIDTH){1'b0}};
    end
    else begin
        dout <= dout_next;
        counter <= counter_next;
    end
end

always @* begin
    if (counter == 0) begin
        dout_next = 1'b0;
    end
    else if (counter == cfg_half) begin
        dout_next = 1'b1;
    end

    if (counter < cfg) begin
        counter_next = counter + 1'b1;
    end
    else begin
        counter_next = {(COUNTER_WIDTH){1'b0}};
    end
end

endmodule
