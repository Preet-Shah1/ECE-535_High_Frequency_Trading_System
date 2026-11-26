module trading_stream_pipeline (
    input  wire        clk,
    input  wire        reset_n,

    input  wire        price_valid,
    output wire        price_ready,
    input  wire [15:0] price_data,

    output wire        decision_valid,
    input  wire        decision_ready,
    output wire [1:0]  decision_data,

    output wire [4:0]  input_count,
    output wire [4:0]  output_count
);

    wire        engine_in_valid;
    wire        engine_in_ready;
    wire [15:0] engine_in_price;

    wire       engine_out_valid;
    wire       engine_out_ready;
    wire [1:0] engine_out_decision;

    // FIFO 1: Prices
    stream_fifo #(
        .WIDTH(16),
        .DEPTH(16)
    ) input_fifo (
        .clk(clk),
        .reset_n(reset_n),

        .in_valid(price_valid),
        .in_ready(price_ready),
        .in_data(price_data),

        .out_valid(engine_in_valid),
        .out_ready(engine_in_ready),
        .out_data(engine_in_price),

        .count(input_count)
    );

    // Streaming trading algorithm
    trading_stream_engine engine (
        .clk(clk),
        .reset_n(reset_n),

        .in_valid(engine_in_valid),
        .in_ready(engine_in_ready),
        .in_price(engine_in_price),

        .out_valid(engine_out_valid),
        .out_ready(engine_out_ready),
        .out_decision(engine_out_decision)
    );

    // FIFO 2: Decisions
    stream_fifo #(
        .WIDTH(2),
        .DEPTH(16)
    ) output_fifo (
        .clk(clk),
        .reset_n(reset_n),

        .in_valid(engine_out_valid),
        .in_ready(engine_out_ready),
        .in_data(engine_out_decision),

        .out_valid(decision_valid),
        .out_ready(decision_ready),
        .out_data(decision_data),

        .count(output_count)
    );

endmodule