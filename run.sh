#!/bin/sh
make && qemu-system-arm -M stm32vldiscovery -kernel firmware -gdb tcp::1234 -S
