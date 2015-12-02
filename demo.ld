MEMORY
{
	/* Cortex-A8 local RAM		--  64 KB  (first 1 KB inaccessible)  */
	a8ram		: org = 0x402F0000, len = 0x10000
	/* OCMC0 memory			--  64 KB  */
	ocmc		: org = 0x40300000, len = 0x10000
}

/* ROM bootloader just loads a single contiguous segment, so make the ELF
 * program headers do the same */
PHDRS {
	image PT_LOAD;
}

/* entrypoint (in ARM mode, at start of image) */
ENTRY( _start )

SECTIONS
{
	/* reserve secure memory in linker map */
	.reserved 0x402f0000 (NOLOAD) : { . += 0x400; } >a8ram :NONE


	/********* output segment (peripheral boot image) *********************/

	/* For peripheral boot, ROM places image at hardcoded addr 0x402f0400 */
	/* For memory boot you can use a different address, e.g. 0x40300000 */
	. = 0x402f0400;
	.text . : {
		KEEP( *( .text._start ) )
		*( .text .text.* )
	} :image

	.rodata : {
		*( .rodata .rodata.* )
/*
		HIDDEN( __init_array_start = . );
		KEEP( *( SORT( .init_array.* ) ) )
		KEEP( *( .init_array ) )
		HIDDEN( __init_array_end = . );
*/
	} :image

	.data : {
		*( .data .data.* )
	} :image

	. = .;

	/********* end of output segment **************************************/


	/* uninitialized shared RAM */
	.shared (NOLOAD) : { *( .shared .shared.* ) } >ocmc :NONE

	/* uninitialized private RAM */
	.noinit (NOLOAD) : { *( .noinit .noinit.* ) } >a8ram :NONE

	/* zero-initialized private RAM */
/*
	.bss : {
		__bss_start = .;
		*( .bss .bss.* COMMON )
		__bss_end = .;
	} >a8ram :NONE
*/


	/* catch any unknown sections and yell loudly about them */
	.orphan : { INPUT_SECTION_FLAGS (SHF_ALLOC) *(*) } :NONE
	ASSERT( SIZEOF(.orphan) == 0, "unassigned sections!" )
}
