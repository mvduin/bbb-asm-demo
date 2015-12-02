// vim: ft=asm
#pragma once

.altmacro
.syntax	unified


// return and conditional return
.macro ret c=	; bx\c&	lr		; .endm


// more or less emulate the simplicity of the Cortex-M series on Cortex-A
//
// for handler mode can use:
//	0b11111  system mode (same stack as thread mode)
//	0b10011  supervisor mode (separate stack, not supported right now)
//
#define MODE_USR 0b10000	// thread-mode, unprivileged
#define MODE_THR 0b11111	// thread-mode, privileged
#define MODE_HND 0b11111	// handler-mode (always privileged)



//-------- macros for defining functions and labeled data --------------------//


// end the current function / data area
.macro .done
.endm

// redefine .done to do nothing
.macro .donedone
	.purgem .done
	.macro .done
	.endm
.endm


// start a function
.macro .fun label
	.done

	.balign	4
	.global	\label&
	.type	\label&, "function"
\label&:

	.purgem .done
	.macro .done
		.size \label&, . - \label&

		.donedone
	.endm
.endm


.macro .var label
	.done

	.balign	4
	.global	\label&
	.type	\label&, "object"
\label&:

	.purgem .done
	.macro .done
		.size \label&, . - \label&

		.donedone
	.endm
.endm
