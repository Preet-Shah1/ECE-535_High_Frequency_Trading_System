
`timescale 1ns/1ps

module tb_trading_engine;

    logic clk = 0;
    logic reset_n = 0;
    logic price_valid = 0;
    logic [15:0] price_cents = 0;

    logic decision_valid;
    logic [1:0] decision;

    localparam logic [1:0] HOLD = 2'b00;
    localparam logic [1:0] BUY  = 2'b01;
    localparam logic [1:0] SELL = 2'b10;

    // 50 MHz clock: 20 ns period
    always #10 clk = ~clk;

    trading_engine dut (
        .clk(clk),
        .reset_n(reset_n),
        .price_valid(price_valid),
        .price_cents(price_cents),
        .decision_valid(decision_valid),
        .decision(decision)
    );

    task automatic test_price(
        input logic [15:0] test_value,
        input logic [1:0] expected
    );
        begin
            @(negedge clk);
            price_cents = test_value;
            price_valid = 1;

            @(posedge clk);
            #1;

            if (!decision_valid || decision !== expected) begin
                $display("FAIL: price=%0d decision=%b expected=%b",
                    test_value, decision, expected);
                $fatal(1);
            end

            $display("PASS: price=%0d decision=%b",
                test_value, decision);

            @(negedge clk);
            price_valid = 0;

            @(posedge clk);
            #1;

            if (decision_valid !== 1'b0)
                $fatal(1, "FAIL: decision_valid must clear");
        end
    endtask

    initial begin
        // Hold reset for two clock cycles
        repeat (2) @(negedge clk);
        reset_n = 1;

        test_price(16'd9950, BUY);
        test_price(16'd10000, HOLD);
        test_price(16'd10125, SELL);
        test_price(16'd0, BUY);
        test_price(16'd65535, SELL);

        $display("ALL TESTS PASSED");
        $finish;
    end

endmodule
