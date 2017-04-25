`timescale 1 ns / 1 ns

module axis_chirp_framer_tb;

reg aclk, aresetn;
wire err_nsmall;

reg [4:0] cfg_nfft;
reg ramp;

reg [15:0] s_tdata;
reg s_tvalid;
wire s_tready;

wire [15:0] m_tdata;
wire [15:0] m_tuser;
wire m_tvalid, m_tlast;
reg m_tready;


axis_chirp_framer #(16, 16) afw (
    aclk,
    aresetn,
    cfg_nfft,
    err_nsmall,
    ramp,
    s_tdata,
    s_tvalid,
    s_tready,
    m_tdata,
    m_tuser,
    m_tvalid,
    m_tlast,
    m_tready
);

localparam NFFT = 5'd12;

reg s_tvalid_next;
reg [10:0] n;

initial begin
    n = 0;
    aclk = 1;
    aresetn = 0;
    cfg_nfft = NFFT; // skip=4, NFFT=12 -> max=4095
    ramp = 0;
    s_tdata = 0;
    s_tvalid = 0;
    m_tready = 1;
    #8 aresetn = 1;
    #16000 ramp = 1;
    #8000 ramp = 0;
    #8000 ramp = 1;
    #8000 ramp = 0;
    #8000 ramp = 1;
    #8000 ramp = 0;
    #8000 ramp = 1;
    #8000 $finish;
end

always
    #1 aclk = ~aclk;

always begin
    #4 if (s_tready) s_tdata = s_tdata + 1;
end

always @(posedge aclk) begin
    //s_tvalid <= s_tvalid_next;

    if (s_tvalid && s_tready)
        s_tvalid <= 0;

    if (m_tvalid && m_tready)
        n <= n + 1;
end

always @(s_tdata) begin
    s_tvalid <= 1;
end

endmodule
