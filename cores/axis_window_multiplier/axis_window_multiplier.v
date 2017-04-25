`timescale 1 ns / 1 ps

module axis_window_multiplier #
(
    S_AXIS_TDATA_WIDTH = 16,
    S_AXIS_TUSER_WIDTH = 16,
    M_AXIS_TDATA_WIDTH = 16,
    COL_NUM = 2,
    COL_WIDTH = 8,
    DATA_WIDTH = COL_NUM*COL_WIDTH,
    ADDR_WIDTH = 12,
    SIGNAL_WIDTH = 14,
    WINDOW_WIDTH = 14,
    FULL_WIDTH = SIGNAL_WIDTH+WINDOW_WIDTH,
    PRODUCT_WIDTH = 14
)
(
    // System
    input wire                                  aclk,
    input wire                                  aresetn,

    // Slave
    input wire signed [S_AXIS_TDATA_WIDTH-1:0]  s_axis_tdata,
    input wire [S_AXIS_TUSER_WIDTH-1:0]         s_axis_tuser,
    input wire                                  s_axis_tvalid,
    input wire                                  s_axis_tlast,
    output wire                                 s_axis_tready,

    // Master
    output wire signed [S_AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
    output wire                                 m_axis_tvalid,
    output wire                                 m_axis_tlast,
    input wire                                  m_axis_tready,

    // BRAM port
    input wire [ADDR_WIDTH-1:0]                 bram_porta_addr,
    input wire [DATA_WIDTH-1:0]                 bram_porta_wrdata,
    input wire [COL_NUM-1:0]                    bram_porta_we
);

localparam PIPELINE_WIDTH = 3;

// BRAM
wire enb;
wire [ADDR_WIDTH-1:0] addrb;
reg [DATA_WIDTH-1:0] dob;
(* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

assign enb = s_axis_tvalid;
assign addrb = s_axis_tuser[ADDR_WIDTH-1:0];

// Pipeline control
reg [PIPELINE_WIDTH-1:0] tvalid;
reg [PIPELINE_WIDTH-1:0] tlast;
wire tready;

assign tready = (~tvalid[PIPELINE_WIDTH-1] | m_axis_tready) & aresetn;

// Datapath
reg signed [SIGNAL_WIDTH-1:0] in_tdata;
reg signed [PRODUCT_WIDTH-1:0] out_tdata;
(* use_dsp48 = "yes" *) reg signed [FULL_WIDTH-1:0] p;
wire signed [SIGNAL_WIDTH-1:0] signal;
wire signed [1+WINDOW_WIDTH-1:0] window;

assign signal = s_axis_tdata[SIGNAL_WIDTH-1:0];
assign window = dob[WINDOW_WIDTH-1:0];

// AXI Stream
assign s_axis_tready = tready;

assign m_axis_tdata = out_tdata;
assign m_axis_tvalid = tvalid[PIPELINE_WIDTH-1];
assign m_axis_tlast = tlast[PIPELINE_WIDTH-1];

integer i;

// Synchronous BRAM
always @(posedge aclk) begin
    // Port A: write new window
    for (i = 0; i < COL_NUM; i = i + 1) begin
        if (bram_porta_we[i]) begin
            ram[bram_porta_addr][i*COL_WIDTH +: COL_WIDTH] <= 
                bram_porta_wrdata[i*COL_WIDTH +: COL_WIDTH];
        end
    end

    // Port B: read window coefficient
    if (enb) begin
        dob <= ram[addrb];
    end
end

// Transfer and multiply pipeline
always @(posedge aclk) begin
    if (~aresetn) begin
        in_tdata <= 0;
        out_tdata <= 0;
        p <= 0;
        tvalid <= 0;
        tlast <= 0;
    end
    else begin
        if (tready) begin
            // Datapath
            if (s_axis_tvalid)
                in_tdata <= signal;
            if (tvalid[0])
                p <= in_tdata * window;
            if (tvalid[PIPELINE_WIDTH-2])
                out_tdata <= p[FULL_WIDTH-1:FULL_WIDTH-PRODUCT_WIDTH];

            // Control by SRs
            tvalid <= {tvalid[PIPELINE_WIDTH-2:0], s_axis_tvalid};
            tlast <= {tlast[PIPELINE_WIDTH-2:0], s_axis_tlast & s_axis_tvalid};
        end
    end
end

endmodule
