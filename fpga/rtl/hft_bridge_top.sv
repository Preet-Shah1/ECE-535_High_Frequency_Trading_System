// ECE 535 DE1-SoC HPS/FPGA top-level wrapper
// Needs official DE1-SoC HPS pin assignments and suitable boot handoff.

module hft_bridge_top (
    input  wire CLOCK_50,
    input  wire KEY0_N,
    output wire [14:0] memory_mem_a,
    output wire [2:0] memory_mem_ba,
    output wire memory_mem_ck,
    output wire memory_mem_ck_n,
    output wire memory_mem_cke,
    output wire memory_mem_cs_n,
    output wire memory_mem_ras_n,
    output wire memory_mem_cas_n,
    output wire memory_mem_we_n,
    output wire memory_mem_reset_n,
    inout  wire [31:0] memory_mem_dq,
    inout  wire [3:0] memory_mem_dqs,
    inout  wire [3:0] memory_mem_dqs_n,
    output wire memory_mem_odt,
    output wire [3:0] memory_mem_dm,
    input  wire memory_oct_rzqin,
    output wire peripheral_hps_io_emac1_inst_TX_CLK,
    output wire peripheral_hps_io_emac1_inst_TXD0,
    output wire peripheral_hps_io_emac1_inst_TXD1,
    output wire peripheral_hps_io_emac1_inst_TXD2,
    output wire peripheral_hps_io_emac1_inst_TXD3,
    input  wire peripheral_hps_io_emac1_inst_RXD0,
    inout  wire peripheral_hps_io_emac1_inst_MDIO,
    output wire peripheral_hps_io_emac1_inst_MDC,
    input  wire peripheral_hps_io_emac1_inst_RX_CTL,
    output wire peripheral_hps_io_emac1_inst_TX_CTL,
    input  wire peripheral_hps_io_emac1_inst_RX_CLK,
    input  wire peripheral_hps_io_emac1_inst_RXD1,
    input  wire peripheral_hps_io_emac1_inst_RXD2,
    input  wire peripheral_hps_io_emac1_inst_RXD3,
    inout  wire peripheral_hps_io_sdio_inst_CMD,
    inout  wire peripheral_hps_io_sdio_inst_D0,
    inout  wire peripheral_hps_io_sdio_inst_D1,
    output wire peripheral_hps_io_sdio_inst_CLK,
    inout  wire peripheral_hps_io_sdio_inst_D2,
    inout  wire peripheral_hps_io_sdio_inst_D3,
    inout  wire peripheral_hps_io_usb1_inst_D0,
    inout  wire peripheral_hps_io_usb1_inst_D1,
    inout  wire peripheral_hps_io_usb1_inst_D2,
    inout  wire peripheral_hps_io_usb1_inst_D3,
    inout  wire peripheral_hps_io_usb1_inst_D4,
    inout  wire peripheral_hps_io_usb1_inst_D5,
    inout  wire peripheral_hps_io_usb1_inst_D6,
    inout  wire peripheral_hps_io_usb1_inst_D7,
    input  wire peripheral_hps_io_usb1_inst_CLK,
    output wire peripheral_hps_io_usb1_inst_STP,
    input  wire peripheral_hps_io_usb1_inst_DIR,
    input  wire peripheral_hps_io_usb1_inst_NXT,
    input  wire peripheral_hps_io_uart0_inst_RX,
    output wire peripheral_hps_io_uart0_inst_TX,
    inout  wire peripheral_hps_io_i2c0_inst_SDA,
    inout  wire peripheral_hps_io_i2c0_inst_SCL,
    inout  wire peripheral_hps_io_gpio_inst_GPIO53
);

    // All four PIOs and the trading engine share CLOCK_50.
    wire [15:0] price_cents;
    wire request_toggle;
    wire [1:0] decision;
    wire decision_valid;
    reg [1:0] decision_latched;
    reg completion_toggle;
    reg last_request;
    reg request_inflight;
    reg pending;

    wire start_request = (request_toggle != last_request) && !pending;

    trading_engine u_trading_engine (
        .clk            (CLOCK_50),
        .reset_n        (KEY0_N),
        .price_valid    (start_request),
        .price_cents    (price_cents),
        .decision_valid (decision_valid),
        .decision       (decision)
    );

    // Each change of control_pio starts one transaction.
    // A completion toggle is only published after the decision is latched.
    always @(posedge CLOCK_50 or negedge KEY0_N) begin
        if (!KEY0_N) begin
            last_request      <= 1'b0;
            request_inflight  <= 1'b0;
            pending           <= 1'b0;
            completion_toggle <= 1'b0;
            decision_latched  <= 2'b00;
        end else begin
            if (start_request) begin
                last_request     <= request_toggle;
                request_inflight <= request_toggle;
                pending          <= 1'b1;
            end
            if (pending && decision_valid) begin
                decision_latched  <= decision;
                completion_toggle <= request_inflight;
                pending           <= 1'b0;
            end
        end
    end

    hft_hps_system u_hps_system (
        .config_clk_clk        (CLOCK_50),
        .reset_n               (KEY0_N),
        .price_export_export   (price_cents),
        .control_export_export (request_toggle),
        .decision_export_export(decision_latched),
        .status_export_export  (completion_toggle),
        .memory_mem_a(memory_mem_a),
        .memory_mem_ba(memory_mem_ba),
        .memory_mem_ck(memory_mem_ck),
        .memory_mem_ck_n(memory_mem_ck_n),
        .memory_mem_cke(memory_mem_cke),
        .memory_mem_cs_n(memory_mem_cs_n),
        .memory_mem_ras_n(memory_mem_ras_n),
        .memory_mem_cas_n(memory_mem_cas_n),
        .memory_mem_we_n(memory_mem_we_n),
        .memory_mem_reset_n(memory_mem_reset_n),
        .memory_mem_dq(memory_mem_dq),
        .memory_mem_dqs(memory_mem_dqs),
        .memory_mem_dqs_n(memory_mem_dqs_n),
        .memory_mem_odt(memory_mem_odt),
        .memory_mem_dm(memory_mem_dm),
        .memory_oct_rzqin(memory_oct_rzqin),
        .peripheral_hps_io_emac1_inst_TX_CLK(peripheral_hps_io_emac1_inst_TX_CLK),
        .peripheral_hps_io_emac1_inst_TXD0(peripheral_hps_io_emac1_inst_TXD0),
        .peripheral_hps_io_emac1_inst_TXD1(peripheral_hps_io_emac1_inst_TXD1),
        .peripheral_hps_io_emac1_inst_TXD2(peripheral_hps_io_emac1_inst_TXD2),
        .peripheral_hps_io_emac1_inst_TXD3(peripheral_hps_io_emac1_inst_TXD3),
        .peripheral_hps_io_emac1_inst_RXD0(peripheral_hps_io_emac1_inst_RXD0),
        .peripheral_hps_io_emac1_inst_MDIO(peripheral_hps_io_emac1_inst_MDIO),
        .peripheral_hps_io_emac1_inst_MDC(peripheral_hps_io_emac1_inst_MDC),
        .peripheral_hps_io_emac1_inst_RX_CTL(peripheral_hps_io_emac1_inst_RX_CTL),
        .peripheral_hps_io_emac1_inst_TX_CTL(peripheral_hps_io_emac1_inst_TX_CTL),
        .peripheral_hps_io_emac1_inst_RX_CLK(peripheral_hps_io_emac1_inst_RX_CLK),
        .peripheral_hps_io_emac1_inst_RXD1(peripheral_hps_io_emac1_inst_RXD1),
        .peripheral_hps_io_emac1_inst_RXD2(peripheral_hps_io_emac1_inst_RXD2),
        .peripheral_hps_io_emac1_inst_RXD3(peripheral_hps_io_emac1_inst_RXD3),
        .peripheral_hps_io_sdio_inst_CMD(peripheral_hps_io_sdio_inst_CMD),
        .peripheral_hps_io_sdio_inst_D0(peripheral_hps_io_sdio_inst_D0),
        .peripheral_hps_io_sdio_inst_D1(peripheral_hps_io_sdio_inst_D1),
        .peripheral_hps_io_sdio_inst_CLK(peripheral_hps_io_sdio_inst_CLK),
        .peripheral_hps_io_sdio_inst_D2(peripheral_hps_io_sdio_inst_D2),
        .peripheral_hps_io_sdio_inst_D3(peripheral_hps_io_sdio_inst_D3),
        .peripheral_hps_io_usb1_inst_D0(peripheral_hps_io_usb1_inst_D0),
        .peripheral_hps_io_usb1_inst_D1(peripheral_hps_io_usb1_inst_D1),
        .peripheral_hps_io_usb1_inst_D2(peripheral_hps_io_usb1_inst_D2),
        .peripheral_hps_io_usb1_inst_D3(peripheral_hps_io_usb1_inst_D3),
        .peripheral_hps_io_usb1_inst_D4(peripheral_hps_io_usb1_inst_D4),
        .peripheral_hps_io_usb1_inst_D5(peripheral_hps_io_usb1_inst_D5),
        .peripheral_hps_io_usb1_inst_D6(peripheral_hps_io_usb1_inst_D6),
        .peripheral_hps_io_usb1_inst_D7(peripheral_hps_io_usb1_inst_D7),
        .peripheral_hps_io_usb1_inst_CLK(peripheral_hps_io_usb1_inst_CLK),
        .peripheral_hps_io_usb1_inst_STP(peripheral_hps_io_usb1_inst_STP),
        .peripheral_hps_io_usb1_inst_DIR(peripheral_hps_io_usb1_inst_DIR),
        .peripheral_hps_io_usb1_inst_NXT(peripheral_hps_io_usb1_inst_NXT),
        .peripheral_hps_io_uart0_inst_RX(peripheral_hps_io_uart0_inst_RX),
        .peripheral_hps_io_uart0_inst_TX(peripheral_hps_io_uart0_inst_TX),
        .peripheral_hps_io_i2c0_inst_SDA(peripheral_hps_io_i2c0_inst_SDA),
        .peripheral_hps_io_i2c0_inst_SCL(peripheral_hps_io_i2c0_inst_SCL),
        .peripheral_hps_io_gpio_inst_GPIO53(peripheral_hps_io_gpio_inst_GPIO53)
    );
endmodule
