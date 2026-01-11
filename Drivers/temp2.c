#include "AES_D.c"
#include "uart.h"
#include "irq.h"
#include <stdint.h>


uart uart0;

volatile uint8_t uart_c ;
volatile uint8_t output[16];
volatile uint8_t input[16];
int main() {
    uart_init(&uart0,(uint32_t *) 0x10008010); // addres of 3rh slave HORNET wb
    uart_c = 0; // prepare for new byte at program start 
    SET_MTVEC_VECTOR_MODE();
    while (1)
    {
    ENABLE_GLOBAL_IRQ(); //activating interrupts on HORNET
    ENABLE_FAST_IRQ(0); //fast interrupt for UART RX 
    while(uart_c < 16){} // wait loop until 16 bytes recieved 

    aes_encrypt(input,output);
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    uart_transmit_string(&uart0, (const char*)output, 16); //send 4 bytes on UART TX
    uart_c = 0;
    }
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