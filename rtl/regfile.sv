// regfile.sv 
// 32x32-bit registers read 2 input/read ports (combinational ports)
// 1 write port only when we is 1 on the rising clock edge
// x0 rule: always reads 0, and writes to it are ignored
// Forcing read to 0 because rf[0] is never written, so it holds "x" in simulation but never be outputted
//
//            ┌──────────────────────────────────────────┐
// ra1[4:0] ──┼──▶ read mux 1 ──▶ (x0 check)  ───────────┼──▶ rd1[31:0]
// ra2[4:0] ──┼──▶ read mux 2 ──▶ (x0 check)  ───────────┼──▶ rd2[31:0]
//            │         ▲            ▲                   │
//            │         └──── rf[31:0] (32 × 32 bits) ───┤
//            │                     ▲                    │
// wa[4:0]  ──┼─────────────────────┤ write on posedge   │
// wd[31:0] ──┼─────────────────────┤ if we && (x0 rule) │
// we       ──┼─────────────────────┘                    │
// clk      ──┼──▶                                       │
//            └──────────────────────────────────────────┘
//            
`timescale 1ns/1ps
`default_nettype none

module regfile(
	input	logic		clk,
	input 	logic		we,	//write enable
	input 	logic	[4:0]	ra1,	//read address 1
	input	logic 	[4:0]	ra2,	//read address 2
	input 	logic 	[4:0]	wa,	//write address
	input	logic	[31:0]	wd,	//write data
	
	output 	logic	[31:0]	rd1,	//read data1
	output	logic	[31:0]	rd2	//read data2
	);

	// ---- 1. Storage ----
	
	logic	[31:0] rf[31:0];	//no reset because software writes registers before reading them
 				
  	// ---- 2. Write port (sequential) ----
  	// clocked block, rising edge
  	// write only when enabled AND the write address is not x0
	
	always_ff @(posedge clk)
		if ((we == 1) && (wa != 0))
			rf[wa] <= wd;

  	// ---- 3. Read ports (combinational) ----
  	// rd1 = 0 if reading x0, otherwise the array entry at ra1
  	// rd2 = same idea for ra2
	
	assign rd1 = (ra1 != 0)? rf[ra1] : 0;
	assign rd2 = (ra2 != 0)? rf[ra2] : 0;

endmodule
`default_nettype wire
