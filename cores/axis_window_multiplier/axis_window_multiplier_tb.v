`timescale 1 ns / 1 ps

module axis_window_multiplier_tb;

reg aclk, aresetn;

reg s_win_tvalid, s_win_tlast, m_win_tready;
wire s_win_tready, m_win_tvalid, m_win_tlast;
reg [11:0] addra;
reg [1:0] we;
reg [15:0] s_win_tdata, s_win_tuser, din;
wire [15:0] m_win_tdata;

wire err_nsmall;

reg [4:0] cfg_nfft;
reg ramp;

reg signed [13:0] tdata;
wire signed [15:0] s_cf_tdata;
assign s_cf_tdata = tdata;
reg s_cf_tvalid;
wire s_cf_tready;

wire [15:0] m_cf_tdata;
wire [15:0] m_cf_tuser;
wire m_cf_tvalid, m_cf_tlast;
reg m_cf_tready;

reg [17:0] cfg_ramp;
wire ramp_rq;
wire [15:0] m_rr_tdata;

axis_ramp_request arr (
    aclk,
    aresetn,
    cfg_ramp,
    ramp_rq,
    m_rr_tdata
);

axis_chirp_framer #(16, 16) afw (
    aclk,
    aresetn,
    cfg_nfft,
    err_nsmall,
    ramp_rq,
    s_cf_tdata,
    s_cf_tvalid,
    s_cf_tready,
    m_cf_tdata,
    m_cf_tuser,
    m_cf_tvalid,
    m_cf_tlast,
    s_win_tready
);

axis_window_multiplier awm (
    aclk,
    aresetn,
    m_cf_tdata,
    m_cf_tuser,
    m_cf_tvalid,
    m_cf_tlast,
    s_win_tready,
    m_win_tdata,
    m_win_tvalid,
    m_win_tlast,
    m_win_tready,
    addra,
    din,
    we
);

localparam NFFT = 5'd10, WIN = 2**NFFT, TL = 125000, DEC_RATE = 62;

always
    #1 aclk = ~aclk;

reg [15:0] hfile [0:WIN-1];
reg signed [13:0] testsignal [0:TL-1];

reg en;
reg beat;
initial begin
    $readmemb("hann_n1024_p14_w16.data", hfile, 0, WIN-1);
    $readmemb("recv_d5000_n1024.data", testsignal, 0, TL-1);
    aclk = 1;
    aresetn = 0;

    n = 0;
    beat=1;
    cfg_ramp = {18'd62500};
    cfg_nfft = NFFT;
    tdata = -8192;
    s_cf_tvalid = 0;
    en = 1;
    fp = 0;

    #8 aresetn = 1;
    #2 m_win_tready = 1;
    #4096 en = 0;
    #100000 $finish;
end

reg [11:0] fp, fp_next;
always @(posedge aclk) begin
    //if (~aresetn) begin
    //    fp <= 0;
    //end
    //else begin
        fp <= fp_next;
        if (we == 2'b11 && en) begin
            addra <= fp;
            din <= hfile[fp];
        end
    //end
end

always @* begin
    if (fp < WIN-1) begin
        fp_next = fp + 1;
        we = 2'b11;
    end
    else begin
        fp_next = 0;
    end
end



reg s_cf_tvalid_next;
integer n;

always begin
    #124 if (aresetn) tdata = testsignal[n];
        n <= n + DEC_RATE;
end

always @(posedge aclk) begin
    //s_cf_tvalid <= s_cf_tvalid_next;

    if (s_cf_tvalid && s_cf_tready)
        s_cf_tvalid <= 0;

end

always @(tdata) begin
    s_cf_tvalid <= 1;
end

always @(posedge ramp_rq) begin
    if (beat) begin
        n = TL/2;
        beat = 0;
    end
    else begin
        n = 0;
        beat = 1;
    end
end


endmodule
