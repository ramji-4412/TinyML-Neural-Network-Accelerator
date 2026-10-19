`timescale 1ns/1ns

module nn_accelerator_tb;

    //========================================================
    // 1. SIGNAL DECLARATIONS
    //========================================================

    logic clk;
    logic rst;
    logic start;

    logic [31:0]  input_features;
    logic [255:0] hidden_weights;
    logic [63:0]  hidden_biases;
    logic [127:0] output_weights;
    logic [15:0]  output_biases;

    logic [15:0] output_scores;
    logic done;

    logic [47:0] test_vectors [0:99];
    logic [31:0] boundary_inputs [0:5];
  	logic [15:0] boundary_expected [0:5];  // ADD THIS LINE

    integer test_index;
    integer boundary_index;
    integer timeout_count;
    integer pass_count;
    integer total_tests;
    integer fail_count;

    //========================================================
    // 2. EXPORTED PYTHON PARAMETERS
    //========================================================

    localparam logic [255:0] EXPORTED_HIDDEN_WEIGHTS =
        256'hFF09FE00FDFFFDFD00FF05F900F400000203FD060002F902FDFC00FE08000500;

    localparam logic [63:0] EXPORTED_HIDDEN_BIASES =
        64'hFDFE0C000B0A080C;

    localparam logic [127:0] EXPORTED_OUTPUT_WEIGHTS =
        128'h000006FAFFFAFB060000F9050806FA01;

    localparam logic [15:0] EXPORTED_OUTPUT_BIASES =
        16'hFDFE;

    //========================================================
    // 3. DUT INSTANTIATION
    //========================================================

    nn_accelerator dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .input_features(input_features),
        .hidden_weights(hidden_weights),
        .hidden_biases(hidden_biases),
        .output_weights(output_weights),
        .output_biases(output_biases),
        .output_scores(output_scores),
        .done(done)
    );

    //========================================================
    // 4. CLOCK GENERATION
    //========================================================

    initial clk = 1'b0;
    always #5 clk = ~clk;

    //========================================================
    // 5. MAIN TEST SEQUENCE
    //========================================================

    initial begin

        //====================================================
        // 5A. INITIALIZE ALL SIGNALS
        //====================================================

        rst             = 1'b1;
        start           = 1'b0;
        input_features  = '0;
        hidden_weights  = '0;
        hidden_biases   = '0;
        output_weights  = '0;
        output_biases   = '0;

        pass_count      = 0;
        total_tests     = 0;
        fail_count      = 0;
        timeout_count   = 0;

        //====================================================
        // 5B. REFERENCE TEST VECTORS
        //
        // [47:40] = expected output 1
        // [39:32] = expected output 0
        // [31:0]  = packed input features
        //====================================================

        test_vectors[0]  = 48'h00F9FA0807F8;
        test_vectors[1]  = 48'h00FF05FD0B0C;
        test_vectors[2]  = 48'hFFF2FCF409F4;
        test_vectors[3]  = 48'h02FC0F08FCF0;
        test_vectors[4]  = 48'h00FF01090806;
        test_vectors[5]  = 48'hF7FEFEFBF4FC;
        test_vectors[6]  = 48'hF606F709FA0C;
        test_vectors[7]  = 48'hFAFA02FAF4F2;
        test_vectors[8]  = 48'h020203100D08;
        test_vectors[9]  = 48'hFC060E10F5FE;
        test_vectors[10] = 48'hFDFD0801F9F6;
        test_vectors[11] = 48'h04F9020C0FF8;
        test_vectors[12] = 48'hF700FCFEF804;
        test_vectors[13] = 48'hFA03F9090009;
        test_vectors[14] = 48'hF800FE03F1FA;
        test_vectors[15] = 48'hF9050804F503;
        test_vectors[16] = 48'hF6FAFDF3F9F8;
        test_vectors[17] = 48'h00FA0DFC02F9;
        test_vectors[18] = 48'h01F6FD030BF8;
        test_vectors[19] = 48'h03FA08FF05FD;
        test_vectors[20] = 48'hF101F8F0F605;
        test_vectors[21] = 48'hFC040702FD08;
        test_vectors[22] = 48'hF9FB01F00604;
        test_vectors[23] = 48'hFEFF080DF9F4;
        test_vectors[24] = 48'hFCF5FAF00FFE;
        test_vectors[25] = 48'hFA00FF02F8FF;
        test_vectors[26] = 48'h07F70D040EF7;
        test_vectors[27] = 48'h01FA0CFD02F8;
        test_vectors[28] = 48'h02FD0B0503FB;
        test_vectors[29] = 48'hFA04FA09FE09;
        test_vectors[30] = 48'h02F801000CFD;
        test_vectors[31] = 48'h00FE01040704;
        test_vectors[32] = 48'hFD0A080D020F;
        test_vectors[33] = 48'hFFF5F1FE0E00;
        test_vectors[34] = 48'hFB02FE0BFE01;
        test_vectors[35] = 48'h03050F0D0709;
        test_vectors[36] = 48'hFD030CFEFB03;
        test_vectors[37] = 48'hF70402F7FE10;
        test_vectors[38] = 48'hF8FB04FCF0F0;
        test_vectors[39] = 48'hF9FB0AF1F8F1;
        test_vectors[40] = 48'h06F908090DFA;
        test_vectors[41] = 48'hFDF4F3F50AFB;
        test_vectors[42] = 48'hFC030CF80209;
        test_vectors[43] = 48'hF709FF0CF70E;
        test_vectors[44] = 48'hF70105F9F3FE;
        test_vectors[45] = 48'hFD020CF9FE03;
        test_vectors[46] = 48'hF9FB03FCF4F4;
        test_vectors[47] = 48'hF9FE0009F1F0;
        test_vectors[48] = 48'hF802F701FD0A;
        test_vectors[49] = 48'hFF040D10FEFE;
        test_vectors[50] = 48'hFCFBFEFB0501;
        test_vectors[51] = 48'hF4FBFDF4F1F3;
        test_vectors[52] = 48'hFDF9FEFB0701;
        test_vectors[53] = 48'h01F4F5090AF2;
        test_vectors[54] = 48'hFBF7F9FCFDF4;
        test_vectors[55] = 48'hFEFE06F60705;
        test_vectors[56] = 48'hFAFEF908FFFF;
        test_vectors[57] = 48'hF704F900FC0D;
        test_vectors[58] = 48'hFCFE0EFEF1F7;
        test_vectors[59] = 48'h02F507F609F4;
        test_vectors[60] = 48'hF500F502F4FF;
        test_vectors[61] = 48'hFCF9FB06FCF2;
        test_vectors[62] = 48'h02000DFE0B0D;
        test_vectors[63] = 48'hFBFA06F103FD;
        test_vectors[64] = 48'hFA04030CF1FB;
        test_vectors[65] = 48'hFAFFF80FF9F8;
        test_vectors[66] = 48'hF4FFF5F2FA04;
        test_vectors[67] = 48'h03000E050602;
        test_vectors[68] = 48'hF806FA06FA0D;
        test_vectors[69] = 48'hF7020EF0F1FE;
        test_vectors[70] = 48'h00FC010D02F6;
        test_vectors[71] = 48'hFEF3FAF80DFC;
        test_vectors[72] = 48'h01000D0CFEFA;
        test_vectors[73] = 48'hFBFF02FB0206;
        test_vectors[74] = 48'hFDF702F204F7;
        test_vectors[75] = 48'hF60C0509F20F;
        test_vectors[76] = 48'hFDF4F5FD05F7;
        test_vectors[77] = 48'hF8FCF5F80809;
        test_vectors[78] = 48'hFDF4F1F81000;
        test_vectors[79] = 48'h00F7FEFE05F9;
        test_vectors[80] = 48'hFD01FF0C0305;
        test_vectors[81] = 48'hFDFBF9FD0905;
        test_vectors[82] = 48'h02FC0BFF04FC;
        test_vectors[83] = 48'hF9FF06FBFA00;
        test_vectors[84] = 48'hFCFFFD010204;
        test_vectors[85] = 48'h04F806080CF5;
        test_vectors[86] = 48'hF300F1F0030F;
        test_vectors[87] = 48'hFCF7F7F909FE;
        test_vectors[88] = 48'hF5FDF9F1FCFE;
        test_vectors[89] = 48'hF40103F2F2FF;
        test_vectors[90] = 48'h00FC050B01F9;
        test_vectors[91] = 48'hFF040A0A0107;
        test_vectors[92] = 48'hFEFB000206FE;
        test_vectors[93] = 48'hF1FEF3F3F5FC;
        test_vectors[94] = 48'hFEFAFDFD0804;
        test_vectors[95] = 48'hFA0003F2070E;
        test_vectors[96] = 48'h04FF0A0B0F03;
        test_vectors[97] = 48'hFC080A07FE0D;
        test_vectors[98] = 48'h05F406FF0AF3;
        test_vectors[99] = 48'hFEF9F70507FE;

        //====================================================
        // 5C. BOUNDARY INPUT VECTORS
        //====================================================

        boundary_inputs[0] = 32'h80808080; // All -128
        boundary_inputs[1] = 32'h7F7F7F7F; // All +127
        boundary_inputs[2] = 32'h00000000; // All zero
        boundary_inputs[3] = 32'hFFFFFFFF; // All -1
        boundary_inputs[4] = 32'h7F807F80; // Mixed +127/-128
        boundary_inputs[5] = 32'h807F807F; // Mixed -128/+127
      
      	boundary_expected[0] = 16'hC0FA; // All -128
		boundary_expected[1] = 16'h2229; // All +127
		boundary_expected[2] = 16'hFDFD; // All zero
		boundary_expected[3] = 16'hFDFD; // All -1
		boundary_expected[4] = 16'h24E4; // Mixed +127/-128
		boundary_expected[5] = 16'hD34E; // Mixed -128/+127

        //====================================================
        // 5D. APPLY RESET AND LOAD TRAINED PARAMETERS
        //====================================================

        repeat (3) @(negedge clk);
        rst = 1'b0;

        hidden_weights = EXPORTED_HIDDEN_WEIGHTS;
        hidden_biases  = EXPORTED_HIDDEN_BIASES;
        output_weights = EXPORTED_OUTPUT_WEIGHTS;
        output_biases  = EXPORTED_OUTPUT_BIASES;

        @(negedge clk);

        $display("");
        $display("========================================");
        $display(" TinyML MULTI-VECTOR VERIFICATION");
        $display(" Architecture: 4-8-2");
        $display(" Fixed-point: Signed Q4.4");
        $display(" Total reference vectors: 100");
        $display("========================================");

        //====================================================
        // 6. RESET TEST 1: RESET WHILE IDLE
        //====================================================

        $display("");
        $display("RESET TEST 1: Reset while idle");

        @(negedge clk);
        rst = 1'b1;
        start = 1'b0;

        repeat (2) @(negedge clk);

        rst = 1'b0;

        repeat (2) @(negedge clk);

        if (done !== 1'b0) begin
            $display("FAIL: done is not low after idle reset");
            $display("done = %b", done);
            $fatal(1, "IDLE RESET TEST FAILED");
        end

        $display("PASS: done is low after idle reset");

        input_features = test_vectors[0][31:0];

        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        timeout_count = 0;

        while ((done !== 1'b1) && (timeout_count < 500)) begin
            @(negedge clk);
            timeout_count = timeout_count + 1;
        end

        if (done !== 1'b1)
            $fatal(1, "FAIL: Timeout after idle reset");

        if (output_scores !== test_vectors[0][47:32]) begin
            $display("Actual:   %h", output_scores);
            $display("Expected: %h", test_vectors[0][47:32]);
            $fatal(1, "IDLE RESET OUTPUT MISMATCH");
        end

        $display("PASS: Inference succeeded after idle reset");
        $display("RESET TEST 1 PASSED");

        //====================================================
        // 7. RESET TEST 2: RESET DURING ACTIVE INFERENCE
        //====================================================

        $display("");
        $display("RESET TEST 2: Reset during active inference");

        input_features = test_vectors[1][31:0];

        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        // Interrupt the ongoing inference.
        repeat (5) @(negedge clk);

        rst = 1'b1;
        start = 1'b0;

        repeat (2) @(negedge clk);

        rst = 1'b0;

        repeat (2) @(negedge clk);

        if (done !== 1'b0) begin
            $display("FAIL: done is high after active reset");
            $fatal(1, "ACTIVE RESET TEST FAILED");
        end
      
      	if (output_scores !== 16'h0000) begin
    		$display("FAIL: output_scores not cleared after active reset");
    		$display("Actual output_scores = %h", output_scores);
    		$fatal(1, "ACTIVE RESET OUTPUT CLEAR FAILED");
		end

		$display("PASS: Reset cleared done and output_scores");

        $display("PASS: Reset cleared the completion status");

        // Start a fresh inference after reset.
        input_features = test_vectors[1][31:0];

        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        timeout_count = 0;

        while ((done !== 1'b1) && (timeout_count < 500)) begin
            @(negedge clk);
            timeout_count = timeout_count + 1;
        end

        if (done !== 1'b1) begin
            $display("FAIL: Timeout after active reset");
            $fatal(1, "ACTIVE RESET TEST FAILED");
        end

        if (output_scores !== test_vectors[1][47:32]) begin
            $display("Actual:   %h", output_scores);
            $display("Expected: %h", test_vectors[1][47:32]);
            $fatal(1, "ACTIVE RESET OUTPUT MISMATCH");
        end

        $display("PASS: Fresh inference succeeded after reset");
        $display("RESET TEST 2 PASSED");

        //====================================================
        // 8. SIGNED INPUT BOUNDARY TEST
        //
        // This section checks completion and known outputs.
        // Exact numerical checks require reference outputs
        // generated using the matching Python model.
        //====================================================

        $display("");
        $display("========================================");
        $display(" SIGNED INPUT BOUNDARY TEST");
        $display("========================================");

        for (boundary_index = 0;
             boundary_index < 6;
             boundary_index = boundary_index + 1) begin

            input_features = boundary_inputs[boundary_index];

            // Wait for previous done indication to clear.
            timeout_count = 0;

            while ((done !== 1'b0) && (timeout_count < 10)) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
            end

            if (done !== 1'b0) begin
                $display("FAIL: done did not clear before boundary %0d",
                         boundary_index);
                $fatal(1, "BOUNDARY TEST FAILED");
            end

            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            timeout_count = 0;

            while ((done !== 1'b1) && (timeout_count < 500)) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
            end

            if (done !== 1'b1) begin
                $display("FAIL: Boundary test %0d timed out",
                         boundary_index);
                $fatal(1, "BOUNDARY TEST FAILED");
            end

            // Reduction XOR returns X if any bit is X or Z.
            // Check for unknown output bits.
			if ((^output_scores) === 1'bx) begin
    			$display("FAIL: Unknown output in boundary test %0d",
             	boundary_index);
    			$fatal(1, "BOUNDARY TEST FAILED");
			end

			// Compare the exact numerical output.
			if (output_scores !== boundary_expected[boundary_index]) begin
    			$display("FAIL: Boundary test %0d", boundary_index);
    			$display("Input:    %h", boundary_inputs[boundary_index]);
    			$display("Actual:   %h", output_scores);
    			$display("Expected: %h", boundary_expected[boundary_index]);
   	 			$fatal(1, "BOUNDARY NUMERICAL CHECK FAILED");
			end

			$display(
    		"PASS: Boundary test %0d | Input=%h | Output=%h",
    			boundary_index,
   				boundary_inputs[boundary_index],
    			output_scores
			);

        end

        $display("BOUNDARY TESTS COMPLETED: 6/6");

        
        //====================================================
        // 9. REPEATED-INFERENCE STRESS TEST: 500 RUNS
        //====================================================

        pass_count  = 0;
        total_tests = 0;
        fail_count  = 0;

        $display("");
        $display("========================================");
        $display(" 500-RUN REPEATED-INFERENCE STRESS TEST");
        $display("========================================");

        for (test_index = 0;
             test_index < 500;
             test_index = test_index + 1) begin

            // Select input from the 100 reference vectors.
            input_features =
                test_vectors[test_index % 100][31:0];

            // Wait for the previous done pulse to clear.
            timeout_count = 0;

            while ((done !== 1'b0) &&
                   (timeout_count < 10)) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
            end

            if (done !== 1'b0) begin
                $display(
                    "FAIL: done did not clear at run %0d",
                    test_index
                );
                $display("done = %b", done);
                fail_count = fail_count + 1;
                $fatal(1, "STRESS TEST FAILED");
            end

            // Assert start for one clock interval.
            @(negedge clk);
            start = 1'b1;

            @(negedge clk);
            start = 1'b0;

            // Wait for inference completion.
            timeout_count = 0;

            while ((done !== 1'b1) &&
                   (timeout_count < 500)) begin
                @(negedge clk);
                timeout_count = timeout_count + 1;
            end

            total_tests = total_tests + 1;

            // Check for timeout or unknown completion.
            if (done !== 1'b1) begin
                $display(
                    "FAIL: Timeout at run %0d",
                    test_index
                );
                $display("done = %b", done);
                fail_count = fail_count + 1;
                $fatal(1, "STRESS TEST FAILED");
            end

            // Compare against the Python reference output.
            if (output_scores !==
                test_vectors[test_index % 100][47:32]) begin

                $display("FAIL: Run %0d", test_index);
                $display("Input:    %h", input_features);
                $display("Actual:   %h", output_scores);
                $display(
                    "Expected: %h",
                    test_vectors[test_index % 100][47:32]
                );

                fail_count = fail_count + 1;
                $fatal(1, "STRESS TEST FAILED");

            end
            else begin
                pass_count = pass_count + 1;
            end

            // Display progress every 50 successful runs.
            if (((test_index + 1) % 50) == 0) begin
                $display(
                    "Progress: %0d / 500 runs passed",
                    test_index + 1
                );
            end

        end

        //====================================================
        // 10. FINAL STRESS TEST SUMMARY
        //====================================================

        $display("");
        $display("========================================");
        $display(" REPEATED-INFERENCE STRESS TEST SUMMARY");
        $display(" Total completed runs: %0d", total_tests);
        $display(" Passed runs:          %0d", pass_count);
        $display(" Failed runs:          %0d", fail_count);

        if ((pass_count == 500) &&
            (fail_count == 0) &&
            (total_tests == 500)) begin

            $display("STRESS TEST PASSED: 500/500");

        end
        else begin
            $fatal(1, "STRESS TEST FAILED");
        end

        $display("========================================");
        $display("SIMULATION COMPLETED SUCCESSFULLY");
      
      	
        
        //====================================================
        // 11. HELD-HIGH START SIGNAL TEST
        //====================================================

        $display("");
        $display("========================================");
        $display(" HELD-HIGH START SIGNAL TEST");
        $display("========================================");

        // Select a known reference input.
        input_features = test_vectors[0][31:0];

        // Ensure the previous done pulse has cleared.
        @(negedge clk);
        start = 1'b0;

        while (done !== 1'b0)
            @(negedge clk);

        // Assert start and keep it HIGH during inference.
        @(negedge clk);
        start = 1'b1;

        // Wait for the first completion while start stays HIGH.
        timeout_count = 0;

        while ((done !== 1'b1) &&
               (timeout_count < 500)) begin
            @(negedge clk);
            timeout_count = timeout_count + 1;
        end

        if (done !== 1'b1)
            $fatal(1, "FAIL: First inference timed out.");

        if (output_scores !== test_vectors[0][47:32])
            $fatal(1, "FAIL: First inference output mismatch.");

        $display("PASS: First inference output is correct.");
        $display("Keeping start HIGH as controller returns to IDLE.");

        // Keep start high while the FSM leaves FINISH and
        // reaches IDLE. The next IDLE clock can accept it again.
        repeat (3)
            @(negedge clk);

        // Deassert start after giving IDLE time to sample it.
        start = 1'b0;

        $display("Start deasserted.");

        // Observe whether the accepted second request completes.
        timeout_count = 0;

        while ((done !== 1'b1) &&
               (timeout_count < 500)) begin
            @(negedge clk);
            timeout_count = timeout_count + 1;
        end

        if (done === 1'b1) begin
            $display(
                "OBSERVATION: Another inference completed."
            );
            $display(
                "Held-high start triggered a second inference."
            );
        end
        else begin
            $display(
                "OBSERVATION: No second completion detected."
            );
        end


        $finish;


    end

endmodule
