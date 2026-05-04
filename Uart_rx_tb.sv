module uart_rx_tb;

  logic clk_i;
  logic rst_n_i;
  logic baud_tick_i;
  logic rx_i;
  logic [2:0] parity_i;
  logic [1:0] data_bits_i;

  logic [7:0] data_o;
  logic data_valid_o;
  logic parity_err_o;
  logic frame_err_o;

  uart_rx dut (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),
    .baud_tick_i(baud_tick_i),
    .rx_i(rx_i),
    .parity_i(parity_i),
    .data_bits_i(data_bits_i),
    .data_o(data_o),
    .data_valid_o(data_valid_o),
    .parity_err_o(parity_err_o),
    .frame_err_o(frame_err_o)
  );

  // clock
  initial clk_i = 0;
  always #5 clk_i = ~clk_i;

  // baud tick (1-cycle pulse)
  int div;
  always @(posedge clk_i) begin
    if (!rst_n_i) begin
      div <= 0;
      baud_tick_i <= 0;
    end else begin
      if (div == 3) begin
        baud_tick_i <= 1;
        div <= 0;
      end else begin
        baud_tick_i <= 0;
        div <= div + 1;
      end
    end
  end

  // send UART frame
  task send_frame(input [7:0] data);
    integer i;
    logic parity_bit;
    begin
      parity_bit = ^data;

      @(posedge baud_tick_i); rx_i = 0; // START

      for (i = 0; i < 8; i++) begin
        @(posedge baud_tick_i);
        rx_i = data[i]; // LSB first
      end

      @(posedge baud_tick_i); rx_i = parity_bit; // PARITY
      @(posedge baud_tick_i); rx_i = 1;          // STOP
    end
  endtask

  initial begin
    rst_n_i = 0;
    rx_i = 1;
    parity_i = 3'b000;     // even
    data_bits_i = 2'b11;   // 8 bits

    #20 rst_n_i = 1;

    send_frame(8'b10110111);

    #200 $finish;
  end

  always @(posedge clk_i) begin
    if (baud_tick_i || data_valid_o) begin
      $display("T=%0t | IN=%b | SHIFT=%b | OUT=%b | VALID=%b | PERR=%b | FERR=%b",
        $time, rx_i, dut.shift_q,
        data_o, data_valid_o,
        parity_err_o, frame_err_o);
    end
  end

endmodule
