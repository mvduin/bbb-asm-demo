#include "asm-defs.h"


//-------------- Allocate stack ----------------------------------------------//

.pushsection .noinit.stack, "aw", %nobits
	.balign	8
.var stack
	.space	512
.done
.set stack_top, .
.popsection


//-------------- Initialization ----------------------------------------------//
//
// called with bl/blx from reset vector

.fun init
	// minimalistic cortex-a8 initialization

	subs	r4, lr, 4	// vector base, except bit 0 indicates thumb

	cpsid	fia, MODE_THR	// thread mode, mask all async exceptions

	ldr	sp, = stack_top

	mcr	p15, 0, r4, c12, c0, 0	// set vector base (bit 0 is ignored)

	mov	r0, (3 << 11)		// enable branch prediction and i-cache
	bfi	r0, r4, 30, 1		// configure arm/thumb-mode exceptions
	mcr	p15, 0, r0, c1, c0, 0	// system control register

	cpsie	a			// enable async aborts

	bl	intc_init
	bl	main

	// If main returns, go into infinite wfi-loop.  This means that purely
	// irq-driven apps only have to do their initialization in main.

.fun idle
	wfi
	b	idle

.done
