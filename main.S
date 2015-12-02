#include "asm-defs.h"
#include "gpio.h"
#include "prcm.h"

.cpu	cortex-a8
.text

// r4	in	interrupt controller (irq_unmask needs it in r4)
.fun main
	push	{ lr }

	ldr	r0, prcm_base

	movs	r1, 2
	str	r1, [ r0, CLK_L4LS ]
	orrs	r1, 1 << 18		// debounce clock enable
	str	r1, [ r0, MOD_GPIO1 ]
	str	r1, [ r0, MOD_GPIO2 ]

1:	ldr	r1, [ r0, MOD_GPIO1 ]
	tst	r1, 3 << 16
	bne	1b
1:	ldr	r1, [ r0, MOD_GPIO2 ]
	tst	r1, 3 << 16
	bne	1b

	ldr	r0, io1_base	// leds are 1.21-24
	bl	io_reset
	mvns	r1, 0xf << 21
	str	r1, [ r0, IO_nOE ]
	movs	r1, 1 << 21
	str	r1, [ r0, IO_SET ]

	ldr	r0, io2_base	// boot-button is 2.8
	bl	io_reset
	movs	r1, 1 << 8
	str	r1, [ r0, IO_FILTER_EN ]	// debounce
	str	r1, [ r0, IO_IRQ_ON_RISE ]
	str	r1, [ r0, IO_IRQ_ON_FALL ]
	str	r1, [ r0, IO_IRQ0_EN ]

	movs	r0, 32
	bl	irq_unmask

	pop	{ pc }


.fun io2_irq0
	ldr	r0, io2_base	// boot-button is 2.8
	movs	r1, 1 << 8
	str	r1, [ r0, IO_IRQ0_CLR ]
	ldr	r1, [ r0, IO_IN ]
	tst	r1, 1 << 8

	ldr	r0, io1_base	// leds are 1.21-24
	beq	1f

	movs	r1, 1 << 22
	str	r1, [ r0, IO_SET ]
	movs	r1, 3 << 23
	str	r1, [ r0, IO_CLR ]
	ret

1:	movs	r1, 3 << 23
	str	r1, [ r0, IO_SET ]
	movs	r1, 1 << 22
	str	r1, [ r0, IO_CLR ]
	ret


// r0	const	gpio controller
// r1	tmp
.fun io_reset
	movs	r1, 2
	str	r1, [ r0, IO_SYSCONFIG ]
1:	ldr	r1, [ r0, IO_SYSSTATUS ]
	tst	r1, 1
	beq	1b

	movs	r1, 0x10
	str	r1, [ r0, IO_SYSCONFIG ]

	movs	r1, 0
	str	r1, [ r0, IO_CONTROL ]

	ret


.var prcm_base
	.word	0x44e00000
.var io1_base
	.word	0x4804c000
.var io2_base
	.word	0x481ac000
