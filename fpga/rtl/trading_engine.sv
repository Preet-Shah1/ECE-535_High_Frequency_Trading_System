module trading_engine (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        price_valid,
    input  logic [15:0] price_cents,

    output logic        decision_valid,
    output logic [1:0]  decision
);

    // Order encodings
    localparam logic [1:0] HOLD = 2'b00;
    localparam logic [1:0] BUY  = 2'b01;
    localparam logic [1:0] SELL = 2'b10;

    // $100.00 threshold expressed in cents
    localparam logic [15:0] THRESHOLD = 16'd10000;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            decision       <= HOLD;
            decision_valid <= 1'b0;
        end
        else begin
            decision_valid <= price_valid;

            if (price_valid) begin
                if (price_cents < THRESHOLD)
                    decision <= BUY;
                else if (price_cents > THRESHOLD)
                    decision <= SELL;
                else
                    decision <= HOLD;
            end
        end
    end

endmodule