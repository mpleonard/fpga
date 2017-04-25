`timescale 1 ns / 1 ps

//////////////////////////////////////////////////////////////////////////////////
// Company: UCL
// Engineer: Martin Pang Leonard
// 
// Create Date: 03/17/2017 04:20:06 PM
// Design Name: fmcw
// Module Name: axis_fmcw_rti
// Project Name: fmcw
// Target Devices: RedPitaya, zynq-z010
// Tool Versions: Vivado 2016.4
// Description: Averages the frequency bins of the upbeat and downbeat of an
// FMCW triangle IF.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module axis_fmcw_rti # (
    parameter integer AXIS_TDATA_WIDTH = 48,
    parameter integer AXIS_TUSER_WIDTH = 16,
    parameter integer STFT_CHANNELS = 3
)
(
    // Systems signals
    input                                       aclk,
    input                                       aresetn,

    // cfg: [7:4] = log2(stft window), [3:0] = log2(fft window)
    input [19:0]                                 cfg_data,

    // FFT data
    input [AXIS_TDATA_WIDTH-1:0]                s_axis_fft_tdata,
    input [AXIS_TUSER_WIDTH-1:0]                s_axis_fft_tuser,
    input                                       s_axis_fft_tlast,
    input                                       s_axis_fft_tvalid,
    output                                      s_axis_fft_tready,

    // Averaged beats
    output [AXIS_TDATA_WIDTH-1:0]               m_axis_avg_tdata,
    output [AXIS_TUSER_WIDTH-1:0]               m_axis_avg_tuser,
    output                                      m_axis_avg_tlast,
    output                                      m_axis_avg_tvalid,
    input                                       m_axis_avg_tready,

    // Microdoppler STFT
    output [AXIS_TDATA_WIDTH*STFT_CHANNELS-1:0] m_axis_stft_tdata,
    output                                      m_axis_stft_tlast,
    output                                      m_axis_stft_tvalid,
    input                                       m_axis_stft_tready
);

// XK_INDEX = m_axis_avg_tuser[11:0]
localparam UPBEAT = 2'd0, DOWNBEAT = 2'd1, TRANSFER = 2'd2, DISABLED = 2'd3;

reg [1:0] state, state_next;

wire [11:0] addr_max;

wire wea, web;
reg ena, enb, en_reg;
reg [11:0] addra, addrb, addr_reg;
wire [AXIS_TDATA_WIDTH-1:0] dia;
reg [AXIS_TDATA_WIDTH-1:0] dib;
wire [AXIS_TDATA_WIDTH-1:0] doa, dob;

reg s_tready;
reg m_tvalid, m_tvalid_reg;
reg done;

reg [AXIS_TDATA_WIDTH-1:0] s_tdata_reg;
reg [11:0] m_tuser_reg;

wire [AXIS_TDATA_WIDTH/2-2:0] din_im, din_re, doa_im, doa_re;
wire [AXIS_TDATA_WIDTH/2-1:0] avg_im, avg_re;

bram_rti ram(aclk, ena, enb, wea, web, addra, addrb, dia, dib, doa, dob);


reg [AXIS_TDATA_WIDTH*STFT_CHANNELS-1:0] m_stft_tdata;
reg m_stft_tlast, m_stft_tvalid;
wire [11:0] counter_stft_max;
reg [11:0] addr_target, counter_stft;


// BRAM port A = read only
assign wea = 1'b0;
assign web = 1'b1;
assign dia = {(AXIS_TDATA_WIDTH){1'bz}};

// Combinatorial logic for average
assign din_im = s_tdata_reg[AXIS_TDATA_WIDTH-1:AXIS_TDATA_WIDTH/2+1];
assign din_re = s_tdata_reg[AXIS_TDATA_WIDTH/2-1:1];
assign doa_im = doa[AXIS_TDATA_WIDTH-1:AXIS_TDATA_WIDTH/2+1];
assign doa_re = doa[AXIS_TDATA_WIDTH/2-1:1];
assign avg_im = din_im + doa_im;
assign avg_re = din_re + doa_re;

assign addr_max = (1 << cfg_data[3:0]) - 1;
assign counter_stft_max = (1 << cfg_data[7:4]) - 1;

// AXIS Slave
assign s_axis_fft_tready = s_tready;

// AXIS Master
assign m_axis_avg_tvalid = m_tvalid;
assign m_axis_avg_tdata = dob;
assign m_axis_avg_tuser = {{(AXIS_TUSER_WIDTH-12){1'b0}}, m_tuser_reg};
assign m_axis_avg_tlast = (m_tuser_reg == addr_max) ? 1'b1 : 1'b0;

assign m_axis_stft_tdata = m_stft_tdata;
assign m_axis_stft_tlast = m_stft_tlast;
assign m_axis_stft_tvalid = m_stft_tvalid;

integer i;

always @* begin
    case (state)
        UPBEAT: begin
            ena = 1'b0;
            enb = s_axis_fft_tvalid & s_axis_fft_tready;
            addra = 12'd0;
            addrb = s_axis_fft_tuser[11:0];
            dib = s_axis_fft_tdata;
            s_tready = ~done;
            m_tvalid = 1'b0;
        end
        DOWNBEAT: begin
            ena = s_axis_fft_tvalid & s_axis_fft_tready;
            enb = en_reg;
            addra = s_axis_fft_tuser[11:0];
            addrb = addr_reg;
            dib = {avg_im, avg_re};
            s_tready = ~done;
            m_tvalid = 1'b0;
        end
        TRANSFER: begin
            ena = 1'b0;
            enb = en_reg;
            addra = 12'd0;
            addrb = addr_reg;
            dib = {(AXIS_TDATA_WIDTH){1'b0}};
            s_tready = 1'b0;
            m_tvalid = m_tvalid_reg;
        end
        default: begin
            ena = 1'b0;
            enb = 1'b0;
            addra = 12'd0;
            addrb = 12'd0;
            dib = {(AXIS_TDATA_WIDTH){1'b0}};
            s_tready = 1'b0;
            m_tvalid = 1'b0;
        end
    endcase
end

always @(posedge aclk) begin
    if (~aresetn) begin
        en_reg <= 1'b0;
        addr_reg <= 12'd0;
        done <= 1'b0;
        m_tvalid_reg <= 1'b0;
        m_tuser_reg <= 12'd0;
        s_tdata_reg <= 1'b0;
        state <= DISABLED;
        state_next <= UPBEAT;
        m_stft_tdata <= {(AXIS_TDATA_WIDTH*STFT_CHANNELS){1'b0}};
        m_stft_tlast <= 1'b0;
        m_stft_tvalid <= 1'b0;
        counter_stft <= 12'd0;
    end
    else begin
        state <= state_next;
        if (done) begin
            done <= 1'b0;
            addr_reg <= 12'd0;
        end
        case (state)
            UPBEAT: begin
                if (s_axis_fft_tready && s_axis_fft_tvalid && s_axis_fft_tlast) begin
                    done <= 1'b1;
                    state_next <= DOWNBEAT;
                end
            end
            DOWNBEAT: begin
                if (s_axis_fft_tready && s_axis_fft_tvalid) begin
                    en_reg <= ena;
                    addr_reg <= addra;
                    s_tdata_reg <= s_axis_fft_tdata;
                    if (s_axis_fft_tlast) begin
                        done <= 1'b1;
                        state_next <= TRANSFER;
                        addr_target <= cfg_data[19:8];
                    end
                end
            end
            TRANSFER: begin
                m_tvalid_reg <= ~done;
                m_tuser_reg <= addr_reg;
                en_reg <= m_axis_avg_tready & ~done;
                if (m_axis_avg_tready && ~done) begin
                    for (i = 0; i < STFT_CHANNELS; i = i + 1) begin
                        if (m_tuser_reg == addr_target+i)
                            m_stft_tdata[i*AXIS_TDATA_WIDTH +: AXIS_TDATA_WIDTH] <= dob;
                    end
                    if (addr_reg == addr_max) begin
                        state_next <= UPBEAT;
                        done <= 1'b1;
                        en_reg <= 1'b0;

                        m_stft_tvalid <= 1'b1;
                        if (counter_stft == counter_stft_max) begin
                            m_stft_tlast <= 1'b1;
                            counter_stft <= 12'd0;
                        end
                        else begin
                            m_stft_tlast <= 1'b0;
                            counter_stft <= counter_stft + 1;
                        end
                    end
                    else
                        addr_reg <= addr_reg + 1;
                end
            end
            default
                state_next <= UPBEAT;
        endcase
        if (m_axis_stft_tready && m_axis_stft_tvalid)
            m_stft_tvalid <= 1'b0;
    end
end

endmodule
