# AES Peripheral (Wishbone Interface)

This repository contains a hardware AES-256 (Advanced Encryption Standard) encryption peripheral designed for the Hornet RV32 processor core. It connects via a 32-bit Wishbone bus and provides hardware acceleration for 128-bit block encryption.

**Current Status:** Functional encryption logic with ROM-based key expansion.

## 📂 Repository Structure

* **`RTL/`**: Verilog source files for the AES hardware, Wishbone wrapper, and logic.
* **`Drivers/`**: C software drivers, header files, and key generation tools for the Hornet core.
* **`Drivers/rom_generator.c`**: Tool to generate the required `round_keys.mem` file.

## ⚙️ Hardware Architecture

The peripheral operates as a memory-mapped slave on the Wishbone bus. It offloads the compute-intensive AES encryption steps (SubBytes, ShiftRows, MixColumns, AddRoundKey) from the CPU.

### Key Features
* **Input:** 128-bit plaintext (accepted as 4 x 32-bit words).
* **Output:** 128-bit ciphertext (provided as 4 x 32-bit words).
* **Control:** Simple polling mechanism (Start/Done bits).
* **Key Schedule:** **ROM-Based**. The hardware does not expand keys on the fly. Pre-computed round keys must be loaded into the hardware memory (`round_keys.mem`) before synthesis/simulation.

## 🗺️ Register Map

The peripheral is accessed via 32-bit memory operations. Offsets are relative to the peripheral's base address (e.g., `0x10000000` or defined system base).

| Offset | Name | R/W | Description |
| :--- | :--- | :--- | :--- |
| **0x00** | `AES_IN_0` | W | Plaintext bits [31:0] |
| **0x04** | `AES_IN_1` | W | Plaintext bits [63:32] |
| **0x08** | `AES_IN_2` | W | Plaintext bits [95:64] |
| **0x0C** | `AES_IN_3` | W | Plaintext bits [127:96] |
| **0x10** | `AES_CTRL` | R/W | **Control/Status Register**.<br>• **Write 1**: Starts the encryption (Read Bit/Start Bit).<br>• **Read**: Returns 1 when encryption is **Done**. |
| **0x14** | `AES_OUT_0` | R | Ciphertext bits [31:0] |
| **0x18** | `AES_OUT_1` | R | Ciphertext bits [63:32] |
| **0x1C** | `AES_OUT_2` | R | Ciphertext bits [95:64] |
| **0x20** | `AES_OUT_3` | R | Ciphertext bits [127:96] |

## 🚀 Integration Guide

### 1. Generating Round Keys
Since the hardware lacks an on-the-fly key expansion unit to save area, you must pre-calculate the round keys.

1.  Navigate to the `Drivers/` folder.
2.  Edit `rom_generator.c` to set your desired 128-bit Key.
3.  Compile and run the generator:
    ```bash
    gcc rom_generator.c -o rom_gen
    ./rom_gen
    ```
4.  This will create a `round_keys.mem` file.
5.  **Copy** `round_keys.mem` into the `RTL/` folder (or wherever your simulator/synthesizer looks for memory initialization files).

### 2. Software Driver (C Code)
To use the peripheral from the Hornet Core, use the provided `AES_code.c` and `AES_H.h`.

**Example Usage:**

```c
#include "AES_H.h"
#include <stdint.h>
#include "uart.h"
#include "irq.h"
volatile uint8_t output[16];
volatile uint8_t input[16];
uart uart0;
volatile int uart_c ;
int main() {
    uart_init(&uart0,(uint32_t *) 0x10008010); // addres of 3rh slave HORNET wb
    uart_c = 0; // prepare for new byte at program start 
    SET_MTVEC_VECTOR_MODE();
    ENABLE_GLOBAL_IRQ(); //activating interrupts on HORNET
    ENABLE_FAST_IRQ(0); //fast interrupt for UART RX 
    while(uart_c < 16){} // wait loop until 16 bytes recieved 
    aes_encrypt(input,output);
    volatile uint8_t aes_transmit[16];
    __asm__ volatile("nop"); // nops are not needed but its better to have
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    for (int i = 0; i < 16; i++) {
          aes_transmit[i] = output[i];
    }
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    uint8_t dummy = 0xaa ;
    uart_transmit_string(&uart0,&dummy,1);
    uart_transmit_string(&uart0,aes_transmit ,16);
    while (1) {
        __asm__ volatile("nop");
    }
    uart_c = 0 ;
}
void mti_handler() {}//empty handlers 
void exc_handler() {}
void mei_handler() {}
void msi_handler() {}

void fast_irq0_handler() {
    char *rx_ptr = (char*)(uart0.base_addr) + UART_RX_ADDR_OFFSET;
    char rx_byte = *rx_ptr;

    if(uart_c < 16) {
        input[uart_c] = rx_byte; // sequential storage
        uart_c++;
    } else {
        DISABLE_GLOBAL_IRQ();
    }
}
void fast_irq1_handler() {} // empty handler
end
```
⚠️ Known Limitations
Static Key: Changing the encryption key requires regenerating round_keys.mem and re-synthesizing (or reloading the FPGA block RAM).
This peripheral is optimized for fixed-key applications or scenarios where key updates are rare and handled via bitstream updates.
