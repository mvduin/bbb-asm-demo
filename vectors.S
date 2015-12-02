#include "asm-defs.h"

.cpu	cortex-a8
.text


.macro .handler name lradjust
 .fun \name&
 .if \lradjust&
	sub	lr, \lradjust&		// fix return address
 .endif
	srsfd	sp!, MODE_HND		// save { lr_irq, spsr_irq } to handler stack
	cps	MODE_HND		// change to handler mode
.endm


.macro hret
	rfefd	sp!			// pop { pc, cpsr }
.endm


// I use b.w to ensure a vector is 4 bytes exactly, but the assembler refuses
// .w suffix in ARM mode (even though it parses it correctly and I see no good
// reason to refuse it) hence this ugly workaround...

.macro b.w args:vararg
	b	\args&
	.align
.endm



	.balign 32
.fun vectors
	bl	init
	b.w	exc_undef
	b.w	exc_syscall
	b.w	exc_iabort	// instruction-side fault and debug trap
	b.w	exc_dabort	// data-side fault (includes cache maintainance)
	b.w	.		// reserved for hypervisor (n/a on cortex-a8)
	// FIQ is unavailable so can have an inline IRQ handler instead

.handler exc_irq, 4
	push	{ r0-r4, r12, lr }

	ldr	r4, intc_base

	ldr	r0, [ r4, 0x40 ]
	cmp	r0, 128
	bhs	1f			// invalid irq number (spurious irq)

	adr	r12, irq_vectors
	ldr	r12, [ r12, r0, lsl 2 ]
	blx	r12			// invoke IRQ handler

1:	bl	eoi
	pop	{ r0-r4, r12, lr }
	hret


// r0	tmp
// r4	const	interrupt controller
.fun eoi
	movs	r0, -1
	str	r0, [ r4, 0x40 ]	// set cur irq to -1 for diagnostic
	movs	r0, 1
	str	r0, [ r4, 0x48 ]	// write eoi bit
	ldr	r0, [ r4, 0x48 ]	// make sure write has completed
	ret


// r0	const	irq
// r1	tmp
// r2	tmp
// r4	const	interrupt controller
.fun irq_unmask
	ands	r1, r0, 31
	movs	r2, 1
	lsls	r2, r1

	adds	r1, r0, r4
	bics	r1, r1, 31

	str	r2, [ r1, 0x88 ]
	ret


// r0	tmp
// r4	tmp
.fun intc_init
	push	{ lr }
	ldr	r4, intc_base		// interrupt controller

	movs	r0, 2			// reset
	str	r0, [ r4, 0x10 ]
1:	ldr	r0, [ r4, 0x14 ]	// wait reset done
	tst	r0, 1
	beq	1b

	bl	eoi
	isb				// XXX is this needed?
	cpsie	i			// enable interrupts

	pop	{ pc }


.var intc_base
	.word	0x48200000


.handler exc_undef, 0
	// Plain hret would retry the invalid instruction, which could be ok
	// if for example you'd implement task switching with lazy fpu/neon
	// register save/restore.  Skipping over the instruction is trickier
	// since it depends on ARM/Thumb mode of the caller and in Thumb mode
	// the size of the instruction.
	b	.


.handler exc_iabort, 4
	b	.


.handler exc_dabort, 8
	b	.


.handler exc_syscall, 0
	// Syscalls are easy: save only lr and dispatch based on r12.
	// Register arguments r0-r3 and return value are transparently passed
	// through to/from the syscall handler.
	// Saving lr is not needed if you have separate handler/process stacks
	// and syscalls are only made by processes and never in handler mode.
	hret


.var irq_vectors
/*  0*/	.word	0		// Cortex-A8 ICECrusher
/*  1*/	.word	0		// Cortex-A8 debug tx
/*  2*/	.word	0		// Cortex-A8 debug rx
/*  3*/	.word	0		// Cortex-A8 PMU
/*  4*/	.word	0		// ELM
/*  5*/	.word	0		// SSM WFI
/*  6*/	.word	0		// SSM
/*  7*/	.word	0		// External IRQ ("NMI")
/*  8*/	.word	0		// L3 firewall error
/*  9*/	.word	0		// L3 interconnect debug error
/* 10*/	.word	0		// L3 interconnect non-debug error
/* 11*/	.word	0		// PRCM MPU irq
/* 12*/	.word	0		// EDMA client 0
/* 13*/	.word	0		// EDMA protection error
/* 14*/	.word	0		// EDMA CC error
/* 15*/	.word	0		// Watchdog 0
/* 16*/	.word	0		// ADC / Touchscreen controller
/* 17*/	.word	0		// USB queue manager and CPPI
/* 18*/	.word	0		// USB port 0
/* 19*/	.word	0		// USB port 1
/* 20*/	.word	0		// PRUSS host event 0
/* 21*/	.word	0		// PRUSS host event 1
/* 22*/	.word	0		// PRUSS host event 2
/* 23*/	.word	0		// PRUSS host event 3
/* 24*/	.word	0		// PRUSS host event 4
/* 25*/	.word	0		// PRUSS host event 5
/* 26*/	.word	0		// PRUSS host event 6
/* 27*/	.word	0		// PRUSS host event 7
/* 28*/	.word	0		// MMC/SD 1
/* 29*/	.word	0		// MMC/SD 2
/* 30*/	.word	0		// I²C 2
/* 31*/	.word	0		// eCAP 0
/* 32*/	.word	io2_irq0	// GPIO 2 irq 0
/* 33*/	.word	0		// GPIO 2 irq 1
/* 34*/	.word	0		// USB wakeup
/* 35*/	.word	0		// PCIe wakeup
/* 36*/	.word	0		// LCD controller
/* 37*/	.word	0		// SGX530 error in IMG bus
/* 38*/	.word	0		// ?
/* 39*/	.word	0		// ePWM 2
/* 40*/	.word	0		// Ethernet core 0 rx low on bufs
/* 41*/	.word	0		// Ethernet core 0 rx dma completion
/* 42*/	.word	0		// Ethernet core 0 tx dma completion
/* 43*/	.word	0		// Ethernet core 0 misc irq
/* 44*/	.word	0		// UART 3
/* 45*/	.word	0		// UART 4
/* 46*/	.word	0		// UART 5
/* 47*/	.word	0		// eCAP 1
/* 48*/	.word	0		// PCIe irq 0 (legacy)
/* 49*/	.word	0		// PCIe irq 1 (MSI)
/* 50*/	.word	0		// PCIe irq 2 (error)
/* 51*/	.word	0		// PCIe irq 3 (power management)
/* 52*/	.word	0		// DCAN 0 irq 0
/* 53*/	.word	0		// DCAN 0 irq 1
/* 54*/	.word	0		// DCAN 0 parity
/* 55*/	.word	0		// DCAN 1 irq 0
/* 56*/	.word	0		// DCAN 1 irq 1
/* 57*/	.word	0		// DCAN 1 parity
/* 58*/	.word	0		// ePWM 0 TZ
/* 59*/	.word	0		// ePWM 1 TZ
/* 60*/	.word	0		// ePWM 2 TZ
/* 61*/	.word	0		// eCAP 2
/* 62*/	.word	0		// GPIO 3 irq 0
/* 63*/	.word	0		// GPIO 3 irq 1
/* 64*/	.word	0		// MMC/SD 0
/* 65*/	.word	0		// SPI 0
/* 66*/	.word	0		// Timer 0
/* 67*/	.word	0		// Timer 1
/* 68*/	.word	0		// Timer 2
/* 69*/	.word	0		// Timer 3
/* 70*/	.word	0		// I²C 0
/* 71*/	.word	0		// I²C 1
/* 72*/	.word	0		// UART 0
/* 73*/	.word	0		// UART 1
/* 74*/	.word	0		// UART 2
/* 75*/	.word	0		// RTC periodic
/* 76*/	.word	0		// RTC alarm
/* 77*/	.word	0		// System mailbox irq 0
/* 78*/	.word	0		// Wakeup-M3
/* 79*/	.word	0		// eQEP 0
/* 80*/	.word	0		// McASP 0 out
/* 81*/	.word	0		// McASP 0 in
/* 82*/	.word	0		// McASP 1 out
/* 83*/	.word	0		// McASP 1 in
/* 84*/	.word	0		// ?
/* 85*/	.word	0		// ?
/* 86*/	.word	0		// ePWM 0
/* 87*/	.word	0		// ePWM 1
/* 88*/	.word	0		// eQEP 1
/* 89*/	.word	0		// eQEP 2
/* 90*/	.word	0		// External DMA/IRQ pin 2
/* 91*/	.word	0		// Watchdog 1
/* 92*/	.word	0		// Timer 4
/* 93*/	.word	0		// Timer 5
/* 94*/	.word	0		// Timer 6
/* 95*/	.word	0		// Timer 7
/* 96*/	.word	0		// GPIO 0 irq 0
/* 97*/	.word	0		// GPIO 0 irq 1
/* 98*/	.word	0		// GPIO 1 irq 0
/* 99*/	.word	0		// GPIO 1 irq 1
/*100*/	.word	0		// GPMC
/*101*/	.word	0		// EMIF 0 error
/*102*/	.word	0		// ?
/*103*/	.word	0		// ?
/*104*/	.word	0		// ?
/*105*/	.word	0		// ?
/*106*/	.word	0		// ?
/*107*/	.word	0		// ?
/*108*/	.word	0		// ?
/*109*/	.word	0		// ?
/*110*/	.word	0		// ?
/*111*/	.word	0		// ?
/*112*/	.word	0		// EDMA TC 0 error
/*113*/	.word	0		// EDMA TC 1 error
/*114*/	.word	0		// EDMA TC 2 error
/*115*/	.word	0		// Touchscreen Pen
/*116*/	.word	0		// ?
/*117*/	.word	0		// ?
/*118*/	.word	0		// ?
/*119*/	.word	0		// ?
/*120*/	.word	0		// SmartReflex 0 (MPU)
/*121*/	.word	0		// SmartReflex 1 (core)
/*122*/	.word	0		// ?
/*123*/	.word	0		// External DMA/IRQ pin 0
/*124*/	.word	0		// External DMA/IRQ pin 1
/*125*/	.word	0		// SPI 1
/*126*/	.word	0		// ?
/*127*/	.word	0		// ?

.done
