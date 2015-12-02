#include "asm-defs.h"

// place in special section to allow linker script to place it at beginning
.section .text._start

// force ARM mode (required by ROM booloader)
.arm

// entrypoint -> jump to reset vector
.fun _start
	ldr	pc, = vectors
.done
