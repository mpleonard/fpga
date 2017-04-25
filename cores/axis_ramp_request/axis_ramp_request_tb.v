`timescale 1 ns / 1 ps;

module axis_ramp_request_tb ();

reg aclk, aresetn;
reg [17:0] cfg;
wire ramp_rq;
wire [15:0] m_tdata;
wire m_tvalid, m_tready;

assign m_tready = 1;

reg [31:0] cycle;

axis_ramp_request rr (
    .aclk(aclk),
    .aresetn(aresetn),
    .cfg(cfg),
    .ramp_rq(ramp_rq),
    .m_axis_tdata(m_tdata),
    .m_axis_tvalid(m_tvalid),
    .m_axis_tready(m_tready)
);

initial begin
    aclk = 0;
    aresetn = 0;
    cfg = {18'd250000};
    #25 aresetn = 1;
    cycle = 0;
    #2000000 $finish;
end

always
    #1 aclk = ~aclk;

always @(posedge aclk)
    cycle <= cycle + 1;

endmodule
