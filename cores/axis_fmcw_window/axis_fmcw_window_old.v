`timescale 1 ns / 1 ps;

//////////////////////////////////////////////////////////////////////////////////
// Company: UCL
// Engineer: Martin Pang Leonard
// 
// Create Date: 03/17/2017 04:20:06 PM
// Design Name: fmcw
// Module Name: axis_fmcw_window
// Project Name: fmcw
// Target Devices: RedPitaya, zynq-z010
// Tool Versions: Vivado 2016.4
// Description: Frames and zero-pads the DDC'd data for the Xilinx FFT core.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module axis_fmcw_window #
(
    parameter integer AXIS_TDATA_WIDTH = 32
)
(
    // System signals
    input wire                          aclk,
    input wire                          aresetn,
    output wire                         err_small,
    
    // Configuration: Transform window size, Chirp beginning skip
    //  size = 1 << cfg_data[4:0] 
    //  skip = cfg_data[7:5]
    input wire [7:0]                    cfg_data,
    
    // Ramp signal
    input wire                          ramp,

    // AXIS Slave
    input wire [AXIS_TDATA_WIDTH-1:0]   s_axis_data_tdata,
    input wire                          s_axis_data_tvalid,
    output wire                         s_axis_data_tready,

    // AXIS Master
    output wire [AXIS_TDATA_WIDTH-1:0]  m_axis_data_tdata,
    output wire                         m_axis_data_tvalid,
    output wire                         m_axis_data_tlast,
    input wire                          m_axis_data_tready
);

reg [1:0] state, state_next;
localparam ZERO = 2'd0, CATCHUP = 2'd1, DATA = 2'd2, WAIT = 2'd3;

reg [11:0] data_counter, data_counter_next, zero_counter, zero_counter_next;
reg err_small_reg;
reg [11:0] max;
reg [2:0] skip;
reg en;

reg [AXIS_TDATA_WIDTH-1:0] m_axis_data_tdata_reg;
reg m_axis_data_tvalid_reg;
reg [AXIS_TDATA_WIDTH-1:0] ddc_data_last;
reg ddc_valid;

assign s_axis_data_tready = 1;
assign m_axis_data_tlast = (zero_counter == max) ? 1 : 0;
assign err_small = err_small_reg;


// cfg_data latch
always @(cfg_data) begin
    max <= (1 << cfg_data[4:0]) - 1;
    skip <= cfg_data[7:5] - 1;
end

// Sequential logic
always @(posedge aclk) begin
    if (~aresetn) begin
        en <= 0;
        state <= WAIT;
        data_counter <= 12'b0;
        zero_counter <= 12'b0;
        err_small_reg <= 0;
    end
    else if (en) begin
        // Update reg
        data_counter <= data_counter_next;
        zero_counter <= zero_counter_next;
        state <= state_next;
        // Incoming DDC transaction, increment data counter
        if (s_axis_data_tvalid) begin
            if (data_counter < max) begin
                data_counter_next <= data_counter + 1;
                err_small_reg <= 0;
            end
            else begin
                // Window size too small, halt until next ramp
                state_next <= WAIT;
                err_small_reg <= 1;
            end
            //if (state != ZERO && data_counter >= skip) begin
            //    state_next <= DATA;
            //end
        end

        // Increment zero counter for every outgoing zero transaction
        if (m_axis_data_tready) begin
            case (state)
                ZERO: begin
                    if (zero_counter < max) begin
                        zero_counter_next <= zero_counter + 1;
                    end
                    else begin
                        zero_counter_next <= 0;
                    end
                end
                CATCHUP: begin
                    if (zero_counter < skip) begin
                        zero_counter_next <= zero_counter + 1;
                    end
                    else begin
                        zero_counter_next <= 0;
                    end
                end
                DATA: begin
                    ddc_valid <= 0;
                end
            endcase
        end
    end
end

always @(state, zero_counter, data_counter) begin
    if (en) begin
        case (state)
            ZERO: begin
                if (zero_counter == max)
                    state_next <= CATCHUP;
            end
            CATCHUP: begin
                if (zero_counter == skip) begin
                    m_axis_data_tvalid_reg <= 0;
                    state_next <= WAIT;
                end
            end
            WAIT: begin
                if (data_counter > skip) begin
                    state_next <= DATA;
                end
            end
        endcase
    end
end

always @(posedge s_axis_data_tvalid) begin
    ddc_data_last <= s_axis_data_tdata;
    ddc_valid <= 1;
end

always @(posedge ramp) begin
    if (en) begin
        zero_counter_next <= data_counter + 1;
    end
    else begin
        en <= 1;
        zero_counter_next <= 0;
    end
    data_counter_next <= 0;
    state_next <= ZERO;
end

always @(state or ddc_data_last or ddc_valid) begin
    if (en) begin
        case (state)
            ZERO: begin
                m_axis_data_tdata_reg <= {(AXIS_TDATA_WIDTH){1'b0}};
                m_axis_data_tvalid_reg <= 1;
            end
            CATCHUP: begin
                m_axis_data_tdata_reg <= {(AXIS_TDATA_WIDTH){1'b0}};
                m_axis_data_tvalid_reg <= 1;
            end
            DATA: begin
                m_axis_data_tdata_reg <= ddc_data_last;
                m_axis_data_tvalid_reg <= ddc_valid;
            end
            WAIT: begin
                m_axis_data_tvalid_reg <= 0;
            end
        endcase
    end
end

assign m_axis_data_tdata = m_axis_data_tdata_reg;
assign m_axis_data_tvalid = (m_axis_data_tvalid_reg & en);

endmodule
