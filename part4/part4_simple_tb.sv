// ESE-507 Project 2, Fall 2022
// This simple testbench is provided to help you in testing Project 2, Part 3.
// This testbench is not sufficient to test the full correctness of your system, it's just
// a relatively small test to help you get started.

// This test will:
//  - load one matrix
//  - load a vector
//  - wait for your system to compute the product
//  - load another vector (with new_matrix == 0)
//  - check that your system computes the product of the old matrix with this new vector
module check_timing();

   logic               clk, reset, input_valid, input_ready, output_valid, output_ready, new_matrix;

   logic signed [13:0] input_data;
   logic signed [27:0] output_data;

   initial clk=0;
   always #5 clk = ~clk;
   

   // Instantiate DUT
   matvec8_part4 dut (clk, reset, input_valid, input_ready, input_data, new_matrix, output_valid, output_ready, output_data);   


   //////////////////////////////////////////////////////////////////////////////////////////////////
   // code to feed some test inputs

   // rb and rb2 represent random bits. Each clock cycle, we will randomize the value of these bits.
   // When rb is 0, we will not let our testbench send new data to the DUT.
   // When rb is 1, we can send data.
   logic rb, rb2;
   always begin
      @(posedge clk);
      #1;
      std::randomize(rb, rb2); // randomize rb
   end

   // Put our test data into these arrays. These are the values we will feed as input into the system.
   logic [13:0] invals[0:79] = '{10, -20,   30, -40,   50,  -60,   70,  80,   // first row of matrix
                                -90, 100, -110, 120, -130,  140, -150, 160,   
                                 -5,  15,  -55,  42,  119,  -41,    6,  -2,
                                 11, -11,   15, -92,   36,  -44,   17,  22,
                                -84, 106, -104, 126,  115,  -45,    2,  -6,
                                  1,  21,  -49,  48,   32,  -48,   13,  18,
                                 17,  -5,   21, -86,  111,  -49,   -2, -10,
                                -78, 112,  -98, 132,   28,  -52,    9,  14,   // last row of matrix
                                -50,  40,   32, -16,   11,  -49,   49, 111,   // first input vector
                                 22, -41,   42,  62,    4,  -55,    7, -8};   // second input vector                                


   logic [0:79] newInputMatrixVals = {1'b1, 71'bx, 1'b0, 7'bx};

   logic signed [27:0] expectedOut[0:15] = '{16100, 5180, 1808, 6789, 5998, 3793, 3412, 7983, // first output vector
                                             3170, -13810, 2358, -1874, 247, 2794, -666, 683}; // second output vector
    
   logic [15:0] j;

   // If input_valid is set to 1, we will put data on input_data.
   // If input_valid is 0, we will put an X on the input_data to test that your system does not 
   // process the invalid input.
   always @* begin
      if (input_valid == 1) begin
         input_data = invals[j];
         new_matrix = newInputMatrixVals[j];
      end
      else begin
         input_data = 'x;
         new_matrix = 'x;
      end
   end

   // If our random bit rb is set to 1, and if j is within the range of our test vector (invals),
   // we will set input_valid to 1.
   always @* begin
      if ((j>=0) && (j<80) && (rb==1'b1)) begin
         input_valid=1;
      end
      else
         input_valid=0;
   end

   // If we set input_valid and input_ready on this clock edge, we will increment j just after
   // this clock edge.
   always @(posedge clk) begin
      if (input_valid && input_ready)
         j <= #1 j+1;
   end

   ////////////////////////////////////////////////////////////////////////////////////////
   // code to receive the output values

   // we will use another random bit (rb2) to determine if we can assert output_ready.
   logic [31:0] i;
   always @* begin
      if ((i>=0) && (i<16) && (rb2==1'b1))
         output_ready = 1;
      else
         output_ready = 0;
   end

   integer errors=0;

   always @(posedge clk) begin
      if (output_ready && output_valid) begin
         if (output_data !== expectedOut[i]) 
            $display("ERROR:   y[%d] = %d     expected output = %d" , i, output_data, expectedOut[i]);
         else
            $display("SUCCESS: y[%d] = %d", i, output_data);
         
         i=i+1;
      end 
   end

   ////////////////////////////////////////////////////////////////////////////////

   initial begin
      j=0; i=0;   
      
      // Before first clock edge, initialize
      output_ready = 0; 
      reset = 0;
   
      // reset
      @(posedge clk); #1; reset = 1; 
      @(posedge clk); #1; reset = 0;

      wait(i==16);

      // Now we're done!

      // Just as a test: wait another 100 cycles and make sure the DUT doesn't assert output_valid again.
      // It shouldn't, because the system finished the inputs it was given, so it should be providing
      // for new output data.
      repeat(100) begin
         @(posedge clk);
         if (output_valid == 1)
             $display("ERROR: DUT asserted output_valid incorrectly");
      end
        
      $finish;
    end
      
   // This is just here to keep the testbench from running forever in case of error.
   // In other words, if your system never produces three outputs, this code will stop 
   // the simulation after 1000 clock cycles.
   initial begin
      repeat(10000) begin
         @(posedge clk);
      end
      $display("Warning: Output not produced within 10000 clock cycles; stopping simulation so it doens't run forever");
      $stop;
   end

endmodule