module stream_fifo #(
    parameter WIDTH = 16,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire clk,
    input  wire reset_n,

    input  wire             in_valid,
    output wire             in_ready,
    input  wire [WIDTH-1:0] in_data,

    output wire             out_valid,
    input  wire             out_ready,
    output wire [WIDTH-1:0] out_data,

    output wire [ADDR_WIDTH:0] count
);

    reg [WIDTH-1:0] memory [0:DEPTH-1];

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0] occupancy;

    wire empty = (occupancy == 0);
    wire full  = (occupancy == DEPTH);

    assign out_valid = !empty;
    assign out_data = memory[rd_ptr];

    wire pop = out_valid && out_ready;

    // Accept a new item if there is space,
    // including when a full FIFO pops an item.
    assign in_ready = !full || pop;

    wire push = in_valid && in_ready;

    assign count = occupancy;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            wr_ptr    <= 0;
            rd_ptr    <= 0;
            occupancy <= 0;
        end else begin

            if (push) begin
                memory[wr_ptr] <= in_data;
                wr_ptr <= wr_ptr + 1'b1;
            end

            if (pop) begin
                rd_ptr <= rd_ptr + 1'b1;
            end

            case ({push, pop})
                2'b10: occupancy <= occupancy + 1'b1;
                2'b01: occupancy <= occupancy - 1'b1;
                default: occupancy <= occupancy;
            endcase
        end
    end

endmodule
