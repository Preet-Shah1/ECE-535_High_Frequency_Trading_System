
module trading_engine_top (
    input  logic       CLOCK_50,
    input  logic [9:0] SW,
    input  logic [3:0] KEY,
    output logic [9:0] LEDR
);

    logic [15:0] price_cents;
    logic [1:0] decision;
    logic decision_valid;

    // Switches select a simulated market price.
    always_comb begin
        case (SW[1:0])
            2'b00: price_cents = 16'd9950;
            2'b01: price_cents = 16'd10000;
            2'b10: price_cents = 16'd10125;
            2'b11: price_cents = 16'd9800;
        endcase
    end

    trading_engine engine (
        .clk(CLOCK_50),
        .reset_n(KEY[0]),
        .price_valid(1'b1),
        .price_cents(price_cents),
        .decision_valid(decision_valid),
        .decision(decision)
    );

    always_comb begin
        LEDR = 10'b0;

        if (decision_valid) begin
            case (decision)
                2'b01: LEDR[0] = 1'b1; // BUY
                2'b00: LEDR[1] = 1'b1; // HOLD
                2'b10: LEDR[2] = 1'b1; // SELL
                default: LEDR = 10'b0;
            endcase
        end
    end

endmodule
