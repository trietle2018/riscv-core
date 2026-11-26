// tb_regfile.sv — <one line description>
`timescale 1ns/1ps

module tb_regfile;          // ← no ports: a testbench is the top level

  // ---- 1. Signals that connect to the DUT ----
  // TODO: one logic signal for every regfile port (same names, same widths)///
  
	logic           clk;
        logic           we;     //write enable
        logic   [4:0]   ra1;    //read address 1
        logic   [4:0]   ra2;    //read address 2
        logic   [4:0]   wa;     //write address
        logic   [31:0]  wd;     //write data
        logic   [31:0]  rd1;    //read data1
        logic   [31:0]  rd2;    //read data2
  // ---- 2. Instantiate the DUT ----
  // TODO: regfile dut ( .clk(clk), ... );
	regfile	dut (
		.clk(clk),
		.we(we),
		.ra1(ra1),
		.ra2(ra2),
		.wa(wa),
		.wd(wd),
		.rd1(rd1),
		.rd2(rd2)
		);

  // ---- 3. Clock generator ----
  // TODO: start clk at 0, flip it every 5 ns (→ 10 ns period)
	initial clk = 0;
	always 	#5 clk = ~clk;
  // ---- 4. Reference model + counters ----
  // TODO: model array (same shape as rf), int errors, int checks
	logic [31:0] model [31:0];
	int errors = 0;
	int checks = 0;

  // ---- 5. Helper tasks ----
  // TODO: task write_reg(addr, data, en): drive inputs on negedge, wait for posedge, update model
  // TODO: task check_read(a1, a2): set ra1/ra2, wait #1, compare with model, count errors
task automatic write_reg(input logic [4:0]addr,
			 input logic [31:0]data,
			 input logic 	en
			 );
	@(negedge clk);
	we = en;		
	wa = addr;
	wd = data;
	@(posedge clk);
	#1;
	we = 1'b0;
	if (en && (addr != 0)) begin
		model[addr] = data;
	end 
endtask

task automatic check_read(
	input logic [4:0] a1,
	input logic [4:0] a2
	);
	ra1 = a1;
	ra2 = a2;
	#1;
	checks++;
	if ((rd1 !== model[a1]) || (rd2 !== model[a2])) begin
		errors++;
	$display("ERROR: x%0d = %h (exp %h), x%0d = %h (exp %h)", a1, rd1, model[a1], a2, rd2, model[a2]);
	end
endtask
  // ---- 6. The tests ----
  initial begin
    // TODO: initialize inputs and model
	we = 0; wa = 0; wd = 0; ra1 = 0; ra2 = 0;
	for (int i = 0; i < 5; i++)
		model[i] = 0;

    // TODO: tests 1–5 from your plan, using the tasks
	$display("TEST 1: dual-port read");
    	write_reg(1,32'hAAAAAAAA,1);
	write_reg(2,32'hDEADBEEF,1);
	write_reg(3,32'hCCCCCCCC,1);
	write_reg(4,32'hDDDDDDDD,1);
	write_reg(5,32'h12345678,1);
	
	check_read(5,2);
	check_read(2,5);

    // TODO: print summary: PASS if errors == 0, else FAIL
    $display("total runs: %0d checks, %0d errors", checks, errors);
    if (errors == 0) 
	    $display("tb_regfile PASS");
    else
	    $display("tb_regfile FAIL");
    
    $finish;
  end

endmodule
