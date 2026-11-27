Register File Test Plan

This is my test plan for rtl/regfile.sv. The testbench is tb/tb_regfile.sv and I run it with Icarus Verilog.

What the register file does
32 registers, each 32 bits
2 read ports (ra1 -> rd1, ra2 -> rd2). Reads are combinational, so no clock is needed.
1 write port (wa, wd, we). It writes on the rising edge of the clock, only when we = 1.
x0 always reads 0, and writing to x0 does nothing.
No reset on the registers, so Vivado can use LUTRAM.
How I'm testing it
The testbench checks itself and prints PASS or FAIL at the end, so I don't have to read waveforms unless something fails.
I keep a model array in the testbench that copies what the registers should hold. Every time the testbench writes, it also updates the model. Every read gets compared to the model.
I change the inputs on the falling edge of the clock so they are stable before the rising edge. Then I wait 1 ns after changing the read addresses before checking the outputs.
I picked test values so that if the design has a bug, the output would be different from the correct one. For example, I write 0xDEADBEEF to x0 instead of 0, because writing 0 would pass even if the x0 check was broken.
I use !== to compare, so an X output counts as a failure.
Tests
Test 1: Read two different registers at the same time
Write 0x12345678 to x5
Write 0xDEADBEEF to x2
Set ra1 = 5, ra2 = 2. Expect rd1 = 0x12345678 and rd2 = 0xDEADBEEF
Swap them: ra1 = 2, ra2 = 5. Expect rd1 = 0xDEADBEEF and rd2 = 0x12345678

Why: checks that both read ports work on their own. If I accidentally wired rd2 to ra1, reading x5 on both ports would still pass, but this test would catch it.

Test 2: x0 is always 0
Write 0xDEADBEEF to x0 (we = 1, wa = 0)
Set ra1 = 0, ra2 = 0. Expect rd1 = rd2 = 0

Why: if the write to x0 isn't blocked, I would read 0xDEADBEEF. If the read isn't forced to 0, I would read X because rf[0] is never written.

Test 3: Write enable
Write 0xAAAAAAAA to x10 with we = 1
Try to write 0x55555555 to x10 with we = 0
Set ra1 = 10. Expect rd1 = 0xAAAAAAAA (unchanged)

Why: if we doesn't work, I would read 0x55555555. I used two different values so I can tell which one came back.

Test 4: Reading a register while it's being written
Write 0xAAAAAAAA to x4
Set we = 1, wa = 4, wd = 0xBBBBBBBB, ra1 = 4, ra2 = 4
Before the clock edge: expect rd1 = rd2 = 0xAAAAAAAA (old value)
After the clock edge: expect rd1 = rd2 = 0xBBBBBBBB (new value)

Why: checks that the write only happens on the clock edge, and that the read updates right away after it.

Test 5: Random test
First, write all registers x1-x31 with random values (and update the model)

repeat about 5000 times:
  1. pick random we, wa, wd
  2. apply them and wait for the clock edge
  3. if (we == 1 and wa != 0) then model[wa] = wd
  4. pick random ra1, ra2
  5. check rd1 == model[ra1] and rd2 == model[ra2]  (model[0] is always 0)
  6. if they don't match, print ERROR and add 1 to the error count

Why: the directed tests only check a few cases. This tries thousands of combinations, including random writes to x0 and cycles with we = 0. Writing all the registers first makes sure I never read a register that is still X.

Pass criteria
The testbench prints 0 errors and TB_REGFILE PASS


## Results

|     Date      | Checks | Errors | Pass? |
|------|--------|--------|--------|       |
| 2026-11-27    |  5007  |   0    |  Yes  |

### Mutation tests (checking that the testbench can fail)

I broke the design on purpose to make sure the tests catch real bugs:

| Bug I added | Caught by | Result |
|---|---|---|
| `rd2` reads with `ra1` instead of `ra2` | Test 1, Test 2 | FAIL (as expected) |
| Removed `we` from the write condition | Test 3 | FAIL (as expected) |

After each one I restored the design with `git restore` and the tests passed again.

## Synthesis check: reset vs no reset

I synthesized the register file with Yosys (`synth_xilinx`) twice, once as designed
(no reset) and once with a reset that clears all registers.

| | No reset | With reset |
|---|---|---|
| LUTRAM (RAM32M) | 12 | 0 |
| Flip-flops (FDRE) | 0 | 992 |
| LUTs | 65 | 757 |

Without a reset, Yosys puts the registers in LUTRAM. With a reset it has to use a
flip-flop for every bit (31 × 32 = 992; x0 is removed because it's never read) plus
a lot of extra LUTs for the read muxes. That's about 11× more logic, so I left the
reset out. RISC-V doesn't require the registers to be reset, since software writes
a register before reading it.

I'll confirm these numbers with Vivado when I get to the FPGA.
