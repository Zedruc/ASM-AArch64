.extern zero_buffer

.section .bss
  input_buf: .skip 128
  original_buf: .skip 128

.section .text
  .global _start

_start:
  // syscall: read(stdin, buf, count)
  mov x8, #63         // sys_read
  mov x0, #0          // stdin fd = 0
  adr x1, input_buf
  mov x2, #128
  svc 0

  // x0 = bytes read
  mov x1, x0          // length of input
  adr x2, input_buf

strip_newline_init:
  cbz x1, end_strip
  ldrb w3, [x2]
  cmp w3, #0x0A       // '\n'
  b.ne skip_char_init
  mov w3, #0          // replace newline with '\0'
  strb w3, [x2]
  b end_strip

skip_char_init:
  add x2, x2, #1
  sub x1, x1, #1
  b strip_newline_init

end_strip:
  // syscall: openat(dirfd, filename, flags, mode)
  mov x8, #56         // sys_openat
  mov x0, #-100       // AT_FDCWD = -100
  adr x1, input_buf
  mov x2, #1602       // O_RDWR | O_APPEND | O_CREAT | O_TRUNC
  mov x3, #0664       // mode rw-rw-r--
  svc 0

  cmp x0, #0
  b.lt end            // if error, exit

  mov x20, x0         // save file fd

input_loop:
  // syscall: read(stdin, buf, count)
  mov x8, #63
  mov x0, #0          // stdin
  adr x1, input_buf
  mov x2, #128
  svc 0

  cmp x0, #0
  ble end             // EOF or error, exit loop

  // Strip newline from input buffer again
  mov x1, x0          // length of read bytes
  adr x2, input_buf

  // store length of input for write() call
  mov x18, x0

// --- Setup ---
strip_newline_loop:
  // empty dest buffer before writing to it
  adr x14, original_buf
  mov x15, #128
  bl zero_buffer

  adr x14, input_buf     // Source buffer (input_buf)
  mov x15, x0	         // Length of input_buf
  adr x18, original_buf  // Destination buffer (original_buf)

  bl copy_string_loop    // Call copy routine

  cbz x1, check_exit
  ldrb w3, [x2]
  cmp w3, #0x0A          // If newline
  b.ne next_char
  mov w3, #0
  strb w3, [x2]

  // x0 = bytes to write = x5 - x1 + 1
  sub x0, x5, x1
  add x0, x0, #1
  b check_exit


// --- Copy routine ---
// Inputs:
//   x14 = src addr
//   x15 = length
//   x18 = dst addr
copy_string_loop:
  mov x16, #0             // offset = 0

copy_loop:
  cmp x16, x15
  b.ge copy_done

  ldrb w3, [x14, x16]     // Load byte from input_buf[offset]
  strb w3, [x18, x16]     // Store to original_buf[offset]

  add x16, x16, #1
  b copy_loop

copy_done:
  ret


next_char:
  add x2, x2, #1
  sub x1, x1, #1
  b strip_newline_loop

check_exit:
  adr x3, input_buf
  mov w4, #'e'
  ldrb w1, [x3]
  cmp w1, w4
  b.ne not_exit
  ldrb w1, [x3, #1]
  mov w4, #'x'
  cmp w1, w4
  b.ne not_exit
  ldrb w1, [x3, #2]
  mov w4, #'i'
  cmp w1, w4
  b.ne not_exit
  ldrb w1, [x3, #3]
  mov w4, #'t'
  cmp w1, w4
  b.ne not_exit
  ldrb w1, [x3, #4]
  cmp w1, #0
  b.ne not_exit

  b end               // matched "exit", exit program

not_exit:
  // syscall: write(fd, buf, count)
  mov x8, #64         // sys_write
  mov x0, x20         // file fd
  adr x1, original_buf
  mov x2, x18         // bytes read from read syscall in x0
  svc 0

  b input_loop

end:
  // syscall: close(fd)
  mov x8, #57         // sys_close
  mov x0, x20
  svc 0

  // syscall: exit(status)
  mov x8, #93         // sys_exit
  mov x0, #0
  svc 0
