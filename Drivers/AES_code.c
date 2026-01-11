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