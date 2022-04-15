.global _start
_start:
	BL  rcc_init
	BL  gpio_init
	BL  uart_init
	BL  systick_init
	B   main
