.global zero_buffer

// --- Zero out buffer routine ---
// Inputs:
//   x14 = buffer addr
//   x15 = length
zero_buffer:
  mov x16, #0

zero_buffer_loop:
  cmp x16, x15
  b.ge zero_buffer_done

  strb wzr, [x14, x16]     // write 0 to buffer[index]

  add x16, x16, #1
  b zero_buffer_loop

zero_buffer_done:
  ret
