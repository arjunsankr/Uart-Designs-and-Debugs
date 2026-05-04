module uart_tx_tb;

  logic clk_i;
  logic rst_n_i;
  logic baud_tick_i;
  logic [7:0] data_i;
  logic data_valid_i;
  logic [2:0] parity_i;
  logic [1:0] data_bits_i;
  logic tx_o;
  logic tx_ready_o;
  logic tx_busy_o;

  // Instantiate DUT
  uart_tx dut (
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),
    .baud_tick_i(baud_tick_i),
    .data_i(data_i),
    .data_valid_i(data_valid_i),
    .parity_i(parity_i),
    .data_bits_i(data_bits_i),
    .tx_o(tx_o),
    .tx_ready_o(tx_ready_o),
    .tx_busy_o(tx_busy_o)
  );


  initial clk_i = 0;
  always #5 clk_i = ~clk_i;

  //baud tick generation
  initial baud_tick_i = 0;
  always  #5baud_tick_i = ~baud_tick_i;

initial begin
  $dumpfile("uart_tx_tb.vcd");
  $dumpvars(0, uart_tx_tb);    
  // $dumpvars(1, uart_tx_tb.dut);
end

  task send_data(
    input [7:0] data,
    input [1:0] bits,
    input [2:0] parity
  );
  begin
    @(posedge clk_i);
    data_i        = data;
    data_bits_i   = bits;
    parity_i      = parity;
    data_valid_i  = 1;

    @(posedge clk_i);
    data_valid_i  = 0;

    $display("Time=%0t | Sent Data=%b | bits=%d | parity=%b",
              $time, data, bits, parity);
  end
  endtask

  // Monitor TX output
  always@(posedge clk_i) begin
    $display("Time=%0t | tx_o=%b | busy=%b | parity=%b | bit_cnt_q=%b | state=%s",
             $time, tx_o, tx_busy_o,dut.parity_bit,dut.bit_cnt_q,dut.state_q.name());
  end

  // Stimulus
  initial begin
    // Initialize
    rst_n_i = 1;
    data_i = 0;
    data_valid_i = 0;
    parity_i = 0;
    data_bits_i = 0;

    // Reset
    #10;
    rst_n_i = 0;

    // Wait a bit
    #10rst_n_i=1;

    // Test cases

    /* 1. 8-bit data, even parity
    send_data(8'b10110111, 2'b11, 3'b000);
    #500;*/

    /* 2. 7-bit data, odd parity
    send_data(8'h55, 2'b10, 3'b001);
    #500;*/

    // 3. 6-bit data, odd
    send_data(8'b10110001, 2'b01, 3'b001);


    /* 4. 5-bit data, space parity
    send_data(8'h1F, 2'b00, 3'b011);
    #500;*/

    #500$finish;
  end

endmodule
