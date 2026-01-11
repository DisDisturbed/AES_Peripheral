#include "AES_H.h"
#include <stdint.h>
#include "uart.h"

//its fucking works dont change it

volatile uint8_t output[16];
volatile uint8_t output1[16];
uart uart0;
int main() {
    uart_init(&uart0,(uint32_t *) 0x10008010); // addres of 3rh slave HORNET wb
    uint8_t input[16] = {
        0x00, 0x11, 0x22, 0x33,
        0x44, 0x55, 0x66, 0x77,
        0x88, 0x99, 0xaa, 0xbb,
        0xcc, 0xdd, 0xee, 0xff
    };

    aes_encrypt(input,output);
    volatile uint8_t aes_transmit[16];
    __asm__ volatile("nop");
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
}
