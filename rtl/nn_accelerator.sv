module fixed_point_mac #(
    parameter int DATA_WIDTH = 8,
    parameter int FRAC_BITS  = 4,
    parameter int ACC_WIDTH  = 32
)(
    input  logic clk,
    input  logic rst,
    input  logic en,

    input  logic signed [DATA_WIDTH-1:0] input_data,
    input  logic signed [DATA_WIDTH-1:0] weight,

    output logic signed [ACC_WIDTH-1:0] accumulator
);

    logic signed [(2*DATA_WIDTH)-1:0] product_raw;
    logic signed [(2*DATA_WIDTH)-1:0] product_scaled;
    logic signed [ACC_WIDTH-1:0] product_extended;

    // Multiply signed input and weight.
    assign product_raw = input_data * weight;

    // Convert the product back to the original fixed-point scale.
    assign product_scaled = product_raw >>> FRAC_BITS;

    // Extend the scaled product to accumulator width.
    assign product_extended = product_scaled;

    // Sequential accumulation.
    always_ff @(posedge clk) begin
        if (rst)
            accumulator <= '0;
        else if (en)
            accumulator <= accumulator + product_extended;
    end

endmodule



module neuron_unit #(
    parameter int INPUTS     = 4,
    parameter int DATA_WIDTH = 8,
    parameter int FRAC_BITS  = 4,
    parameter int ACC_WIDTH  = 32,
    parameter bit USE_RELU   = 1'b1
)(
    input  logic clk,
    input  logic rst,
    input  logic start,

    input  logic [INPUTS*DATA_WIDTH-1:0] inputs_flat,
    input  logic [INPUTS*DATA_WIDTH-1:0] weights_flat,
    input  logic signed [DATA_WIDTH-1:0] bias,

    output logic signed [DATA_WIDTH-1:0] activation,
    output logic done
);

    typedef enum logic [1:0] {
        IDLE,
        MAC_RESET,
        MAC_RUN,
        ACTIVATE
    } state_t;

    state_t state;

    logic [$clog2(INPUTS+1)-1:0] index;

    logic mac_rst, mac_en;

    logic signed [DATA_WIDTH-1:0] current_input;
    logic signed [DATA_WIDTH-1:0] current_weight;

    logic signed [ACC_WIDTH-1:0] accumulator;
    logic signed [ACC_WIDTH:0] biased_sum;

    localparam logic signed [DATA_WIDTH-1:0] MAX_POS =
        {1'b0, {(DATA_WIDTH-1){1'b1}}};

    localparam logic signed [DATA_WIDTH-1:0] MIN_NEG =
        {1'b1, {(DATA_WIDTH-1){1'b0}}};

    always_comb begin
        current_input =
            $signed(inputs_flat[index*DATA_WIDTH +: DATA_WIDTH]);

        current_weight =
            $signed(weights_flat[index*DATA_WIDTH +: DATA_WIDTH]);
    end

    assign mac_rst = (state == MAC_RESET);
    assign mac_en  = (state == MAC_RUN);

    fixed_point_mac #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .ACC_WIDTH(ACC_WIDTH)
    ) mac_inst (
        .clk(clk),
        .rst(mac_rst),
        .en(mac_en),
        .input_data(current_input),
        .weight(current_weight),
        .accumulator(accumulator)
    );

    // Extend accumulator and bias to the same width.
    always_comb begin
        biased_sum =
            $signed({accumulator[ACC_WIDTH-1], accumulator}) +
            $signed({
                {(ACC_WIDTH+1-DATA_WIDTH){bias[DATA_WIDTH-1]}},
                bias
            });
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            index      <= '0;
            activation <= '0;
            done       <= 1'b0;
        end
        else begin
            done <= 1'b0;

            case (state)

                IDLE: begin
                    if (start) begin
                        index <= '0;
                        state <= MAC_RESET;
                    end
                end

                MAC_RESET: begin
                    index <= '0;
                    state <= MAC_RUN;
                end

                MAC_RUN: begin
                    if (index == INPUTS-1)
                        state <= ACTIVATE;
                    else
                        index <= index + 1'b1;
                end

                ACTIVATE: begin
                    if (USE_RELU) begin
                        // Hidden layer: ReLU with positive saturation.
                        if (biased_sum <= 0)
                            activation <= '0;
                        else if (biased_sum > MAX_POS)
                            activation <= MAX_POS;
                        else
                            activation <= biased_sum[DATA_WIDTH-1:0];
                    end
                    else begin
                        // Output layer: linear activation with
                        // signed saturation.
                        if (biased_sum > MAX_POS)
                            activation <= MAX_POS;
                        else if (biased_sum < MIN_NEG)
                            activation <= MIN_NEG;
                        else
                            activation <= biased_sum[DATA_WIDTH-1:0];
                    end

                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule

module nn_accelerator #(
    parameter int DATA_WIDTH    = 8,
    parameter int FRAC_BITS     = 4,
    parameter int ACC_WIDTH     = 32,
    parameter int INPUTS        = 4,
    parameter int HIDDEN_NEURONS = 8,
    parameter int OUTPUTS       = 2
)(
    input logic clk,
    input logic rst,
    input logic start,

    // Four input features, packed in 8-bit fields.
    input logic [INPUTS*DATA_WIDTH-1:0] input_features,

    // Each hidden neuron has INPUTS weights.
    input logic [
        HIDDEN_NEURONS*INPUTS*DATA_WIDTH-1:0
    ] hidden_weights,

    input logic [
        HIDDEN_NEURONS*DATA_WIDTH-1:0
    ] hidden_biases,

    // Each output neuron has HIDDEN_NEURONS weights.
    input logic [
        OUTPUTS*HIDDEN_NEURONS*DATA_WIDTH-1:0
    ] output_weights,

    input logic [
        OUTPUTS*DATA_WIDTH-1:0
    ] output_biases,

    output logic [
        OUTPUTS*DATA_WIDTH-1:0
    ] output_scores,

    output logic done
);

    localparam int H_IDX_WIDTH =
        (HIDDEN_NEURONS <= 1) ? 1 : $clog2(HIDDEN_NEURONS);

    localparam int O_IDX_WIDTH =
        (OUTPUTS <= 1) ? 1 : $clog2(OUTPUTS);

    typedef enum logic [2:0] {
        IDLE,
        START_HIDDEN,
        WAIT_HIDDEN,
        START_OUTPUT,
        WAIT_OUTPUT,
        FINISH
    } state_t;

    state_t state;

    logic [H_IDX_WIDTH-1:0] hidden_index;
    logic [O_IDX_WIDTH-1:0] output_index;

    logic hidden_start;
    logic hidden_done;

    logic output_start;
    logic output_done;

    logic signed [DATA_WIDTH-1:0] hidden_activation;
    logic signed [DATA_WIDTH-1:0] output_activation;

    logic [
        HIDDEN_NEURONS*DATA_WIDTH-1:0
    ] hidden_activations;

    logic [
        INPUTS*DATA_WIDTH-1:0
    ] selected_hidden_weights;

    logic signed [DATA_WIDTH-1:0] selected_hidden_bias;

    logic [
        HIDDEN_NEURONS*DATA_WIDTH-1:0
    ] selected_output_weights;

    logic signed [DATA_WIDTH-1:0] selected_output_bias;

    // Select parameters for the current hidden neuron.
    always_comb begin
        selected_hidden_weights =
            hidden_weights[
                hidden_index*INPUTS*DATA_WIDTH
                +: INPUTS*DATA_WIDTH
            ];

        selected_hidden_bias =
            $signed(
                hidden_biases[
                    hidden_index*DATA_WIDTH +: DATA_WIDTH
                ]
            );

        selected_output_weights =
            output_weights[
                output_index*HIDDEN_NEURONS*DATA_WIDTH
                +: HIDDEN_NEURONS*DATA_WIDTH
            ];

        selected_output_bias =
            $signed(
                output_biases[
                    output_index*DATA_WIDTH +: DATA_WIDTH
                ]
            );
    end

    // One reusable hidden-layer neuron engine.
    neuron_unit #(
        .INPUTS(INPUTS),
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .ACC_WIDTH(ACC_WIDTH),
        .USE_RELU(1'b1)
    ) hidden_engine (
        .clk(clk),
        .rst(rst),
        .start(hidden_start),
        .inputs_flat(input_features),
        .weights_flat(selected_hidden_weights),
        .bias(selected_hidden_bias),
        .activation(hidden_activation),
        .done(hidden_done)
    );

    // One reusable output-layer neuron engine.
    neuron_unit #(
        .INPUTS(HIDDEN_NEURONS),
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .ACC_WIDTH(ACC_WIDTH),
        .USE_RELU(1'b0)
    ) output_engine (
        .clk(clk),
        .rst(rst),
        .start(output_start),
        .inputs_flat(hidden_activations),
        .weights_flat(selected_output_weights),
        .bias(selected_output_bias),
        .activation(output_activation),
        .done(output_done)
    );

    // Controller: calculate hidden neurons, then output neurons.
    always_ff @(posedge clk) begin
        if (rst) begin
            state             <= IDLE;
            hidden_index      <= '0;
            output_index      <= '0;
            hidden_start      <= 1'b0;
            output_start      <= 1'b0;
            hidden_activations <= '0;
            output_scores     <= '0;
            done              <= 1'b0;
        end
        else begin
            // Start signals and done are pulses.
            hidden_start <= 1'b0;
            output_start <= 1'b0;
            done         <= 1'b0;

            case (state)

                IDLE: begin
                    if (start) begin
                        hidden_index <= '0;
                        output_index <= '0;
                        hidden_activations <= '0;
                        output_scores <= '0;
                        state <= START_HIDDEN;
                    end
                end

                START_HIDDEN: begin
                    hidden_start <= 1'b1;
                    state <= WAIT_HIDDEN;
                end

                WAIT_HIDDEN: begin
                    if (hidden_done) begin
                        hidden_activations[
                            hidden_index*DATA_WIDTH +: DATA_WIDTH
                        ] <= hidden_activation;

                        if (hidden_index == HIDDEN_NEURONS-1) begin
                            output_index <= '0;
                            state <= START_OUTPUT;
                        end
                        else begin
                            hidden_index <= hidden_index + 1'b1;
                            state <= START_HIDDEN;
                        end
                    end
                end

                START_OUTPUT: begin
                    output_start <= 1'b1;
                    state <= WAIT_OUTPUT;
                end

                WAIT_OUTPUT: begin
                    if (output_done) begin
                        output_scores[
                            output_index*DATA_WIDTH +: DATA_WIDTH
                        ] <= output_activation;

                        if (output_index == OUTPUTS-1) begin
                            state <= FINISH;
                        end
                        else begin
                            output_index <= output_index + 1'b1;
                            state <= START_OUTPUT;
                        end
                    end
                end

                FINISH: begin
                    done <= 1'b1;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
