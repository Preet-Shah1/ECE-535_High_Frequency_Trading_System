
module LED_blink (
    input wire CLOCK_50,
    output reg LEDR
);

    // 50 MHz clock
    // Toggle every 25 million cycles
    // Full blink period = 1 second

    reg [24:0] counter = 0;

    initial LEDR = 0;

    always @(posedge CLOCK_50) begin
        if (counter == 25_000_000 - 1) begin
            counter <= 0;
            LEDR <= ~LEDR;
        end else begin
            counter <= counter + 1'b1;
        end
    end

endmodule
