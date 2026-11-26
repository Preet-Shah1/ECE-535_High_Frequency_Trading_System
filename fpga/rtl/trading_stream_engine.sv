module trading_stream_engine (
    input  wire        clk,
    input  wire        reset_n,

    // Streaming input
    input  wire        in_valid,
    output wire        in_ready,
    input  wire [15:0] in_price,

    // Streaming output
    output reg         out_valid,
    input  wire        out_ready,
    output reg  [1:0]  out_decision
);

    // One-stage elastic pipeline:
    // Accept new data if the output register is empty or the previous result is consumed.
    assign in_ready = !out_valid || out_ready;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            out_valid    <= 1'b0;
            out_decision <= 2'b00;
        end else if (in_ready) begin

            out_valid <= in_valid;
 
            if (in_valid) begin
                if (in_price < 16'd10000)
                    out_decision <= 2'b01; // BUY

                else if (in_price > 16'd10000)
                    out_decision <= 2'b10; // SELL

                else
                    out_decision <= 2'b00; // HOLD
            end
        end
    end

endmodule
