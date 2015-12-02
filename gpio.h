#pragma once

#define IO_SYSCONFIG	0x010
#define IO_SYSSTATUS	0x114
#define IO_CONTROL	0x130

#define IO_nOE		0x134
#define IO_IN		0x138
#define IO_OUT		0x13c
#define IO_CLR		0x190
#define IO_SET		0x194

#define IO_FILTER_TIME	0x154
#define IO_FILTER_EN	0x150

#define IO_IRQ_ON_LOW	0x140
#define IO_IRQ_ON_HIGH	0x144
#define IO_IRQ_ON_RISE	0x148
#define IO_IRQ_ON_FALL	0x14c

#define IO_IRQ0		0x02c
#define IO_IRQ0_SET	0x024
#define IO_IRQ0_CLR	0x02c
#define IO_IRQ0_EN	0x034
#define IO_IRQ0_DIS	0x03c

#define IO_IRQ1		0x030
#define IO_IRQ1_SET	0x028
#define IO_IRQ1_CLR	0x030
#define IO_IRQ1_EN	0x038
#define IO_IRQ1_DIS	0x040
