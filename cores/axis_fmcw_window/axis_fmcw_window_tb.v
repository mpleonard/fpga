`timescale 1 ns / 1 ns

module axis_fmcw_window_tb;

reg aclk, aresetn;
wire err_nsmall;
wire err_overskip;

reg [7:0] cfg_data;
wire [15:0] sts_data;
reg ramp;

reg [47:0] s_tdata;
reg s_tvalid;
wire s_tready;

wire [47:0] m_tdata;
wire m_tvalid, m_tlast;
reg m_tready;


axis_fmcw_window #(48) afw (
    .aclk(aclk),
    .aresetn(aresetn),
    .err_nsmall(err_nsmall),
    .err_overskip(err_overskip),
    .cfg_data(cfg_data),
    .sts_data(sts_data),
    .ramp(ramp),
    .s_axis_data_tdata(s_tdata),
    .s_axis_data_tvalid(s_tvalid),
    .s_axis_data_tready(s_tready),
    .m_axis_data_tdata(m_tdata),
    .m_axis_data_tvalid(m_tvalid),
    .m_axis_data_tlast(m_tlast),
    .m_axis_data_tready(m_tready)
);

localparam SKIP = 3'd4, NFFT = 5'd10;

reg [23:0] i, q;
reg s_tvalid_next;
reg [10:0] n;

initial begin
    n = 0;
    aclk = 0;
    aresetn = 0;
    cfg_data = {SKIP, NFFT}; // skip=4, NFFT=12 -> max=4095
    ramp = 0;
    s_tvalid = 0;
    i = 0;
    q = 0;
    m_tready = 1;
    #8 aresetn = 1;
    #100 ramp = 1;
    #100 ramp = 0;
    #60000 ramp = 1;
    #100 ramp = 0;
    #60000 ramp = 1;
    #100 ramp = 0;
    #60000 ramp = 1;
    #100 ramp = 0;
    #60000 ramp = 1;
    #100 ramp = 0;
    #60000 ramp = 1;
    #100 ramp = 0;
    //#256000 ramp = 1;
    //#100 ramp = 0;
    #60000 $finish;
end

always
    #1 aclk = ~aclk;

always begin
    #64 i = i + 1;
    q = q + 1; 
end

always @(posedge aclk) begin
    s_tdata <= {q, i};
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
