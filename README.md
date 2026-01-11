# AES Peripheral (Wishbone Interface)

This repository contains a hardware AES-256 (Advanced Encryption Standard) encryption peripheral designed for the Hornet RV32 processor core. It connects via a 32-bit Wishbone bus and provides hardware acceleration for 128-bit block encryption.

**Current Status:** Functional encryption logic with ROM-based key expansion.

## 📂 Repository Structure

* **`RTL/`**: Verilog source files for the AES hardware, Wishbone wrapper, and logic.
* **`Drivers/`**: C software drivers and header files for the Hornet core.

## ⚙️ Hardware Architecture

The peripheral operates as a memory-mapped slave on the Wishbone bus. It offloads the compute-intensive AES encryption steps (SubBytes, ShiftRows, MixColumns, AddRoundKey) from the CPU.

### Key Features
* **Input:** 128-bit plaintext (accepted as 4 x 32-bit words).
* **Output:** 128-bit ciphertext (provided as 4 x 32-bit words).
* **Control:** Simple polling mechanism (Start/Done bits).
* **Key Schedule:** **ROM-Based**. The hardware does not expand keys on the fly. Pre-computed round keys must be loaded into the hardware memory (`round_keys.mem`) before synthesis/simulation.

## 🗺️ Register Map

The peripheral is accessed via 32-bit memory operations. Offsets are relative to the peripheral's base address (System Base + `0x30`).

| Offset | Name | R/W | Description |
| :--- | :--- | :--- | :--- |
| **0x30** | `AES_IN_0` | W | Plaintext bits [31:0] |
| **0x34** | `AES_IN_1` | W | Plaintext bits [63:32] |
| **0x38** | `AES_IN_2` | W | Plaintext bits [95:64] |
| **0x3C** | `AES_IN_3` | W | Plaintext bits [127:96] |
| **0x40** | `AES_CTRL` | W | **Control Register**.<br>• **Write 1**: Starts the encryption. |
| **0x44** | `AES_STATUS` | R | **Status Register**.<br>• **Read 1**: Encryption is Done (Result ready). |
| **0x48** | `AES_OUT_0` | R | Ciphertext bits [31:0] |
| **0x4C** | `AES_OUT_1` | R | Ciphertext bits [63:32] |
| **0x50** | `AES_OUT_2` | R | Ciphertext bits [95:64] |
| **0x54** | `AES_OUT_3` | R | Ciphertext bits [127:96] |

## 🚀 Integration Guide

### 1. Generating Round Keys
Since the hardware lacks an on-the-fly key expansion unit to save area, you must pre-calculate the round keys.
* For verification, this site is useful: [Cryptool AES Step-by-Step](https://legacy.cryptool.org/en/cto/aes-step-by-step)

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
volatile int uart_c;

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
