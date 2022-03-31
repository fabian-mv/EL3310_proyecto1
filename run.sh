#!/bin/sh
make && qemu-system-arm -M stm32vldiscovery -kernel firmware -serial stdio -gdb tcp::1234 -S
