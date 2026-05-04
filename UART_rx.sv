module uart_rx (
  input  logic clk_i,
  input  logic rst_n_i,
  input  logic baud_tick_i,
  input  logic rx_i,
  input  logic [2:0] parity_i,
  input  logic [1:0] data_bits_i,

  output logic [7:0] data_o,
  output logic data_valid_o,
  output logic parity_err_o,
  output logic frame_err_o
);

  typedef enum logic [1:0] {IDLE, DATA, PARITY, STOP} state_t;
  state_t state_q, state_d;

  logic [7:0] shift_q;
  logic [3:0] bit_cnt_q;
  logic [3:0] data_max;
  logic parity_calc;

  // data width
  always_comb begin
    case (data_bits_i)
      2'b00: data_max = 4'd5;
      2'b01: data_max = 4'd6;
      2'b10: data_max = 4'd7;
      default: data_max = 4'd8;
    endcase
  end

  // parity calc (even/odd only)
  always_comb begin
    case (parity_i)
      3'b000: parity_calc = ^shift_q;
      3'b001: parity_calc = ~^shift_q;
      default: parity_calc = 1'b0;
    endcase
  end

  // state register
  always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i)
      state_q <= IDLE;
    else
      state_q <= state_d;
  end

  // FSM
  always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
      shift_q <= 0;
      bit_cnt_q <= 0;
      data_o <= 0;
      data_valid_o <= 0;
      parity_err_o <= 0;
      frame_err_o <= 0;
      state_d <= IDLE;
    end else begin

      data_valid_o <= 0;
      state_d <= state_q;

      case (state_q)

        IDLE: begin
          if (baud_tick_i && rx_i == 0) begin
            bit_cnt_q <= 0;
            state_d <= DATA;
          end
        end

        DATA: begin
          if (baud_tick_i) begin
            shift_q <= {rx_i, shift_q[7:1]};

            if (bit_cnt_q == data_max - 1) begin
              bit_cnt_q <= 0;
              state_d <= PARITY;
            end else begin
              bit_cnt_q <= bit_cnt_q + 1;
            end
          end
        end

        PARITY: begin
          if (baud_tick_i) begin
            parity_err_o <= (rx_i != parity_calc);
            state_d <= STOP;
          end
        end

        STOP: begin
          if (baud_tick_i) begin
            frame_err_o <= (rx_i != 1'b1);
            data_o <= shift_q;
            data_valid_o <= 1;
            state_d <= IDLE;
          end
        end

      endcase
    end
  end

endmodule
