#include "AES_D.c"
#include "uart.h"
#include "irq.h"
#include <stdint.h>

uart uart0;

volatile uint32_t s0;
volatile uint32_t s1;
volatile uint32_t s2;
volatile uint32_t s3;


volatile uint8_t in[16]={0xde,0xad,0xbe,0xef,0xde,0xad,0xbe,0xef,0xde,0xad,0xbe,0xef,0xde,0xad,0xbe,0xef};
    volatile uint32_t *in0 = (uint32_t *)(AES_BASE_ADDR + AES_IN0_OFFSET);
    volatile uint32_t *in1 = (uint32_t *)(AES_BASE_ADDR + AES_IN1_OFFSET);
    volatile uint32_t *in2 = (uint32_t *)(AES_BASE_ADDR + AES_IN2_OFFSET);
    volatile uint32_t *in3 = (uint32_t *)(AES_BASE_ADDR + AES_IN3_OFFSET);
    volatile uint32_t *in4 = (uint32_t *)(AES_BASE_ADDR + AES_CTRL_OFFSET);
    
    
    volatile uint32_t *out0 = (uint32_t *)(AES_BASE_ADDR + AES_OUT0_OFFSET);
    volatile uint32_t *out1 = (uint32_t *)(AES_BASE_ADDR + AES_OUT1_OFFSET);
    volatile uint32_t *out2 = (uint32_t *)(AES_BASE_ADDR + AES_OUT2_OFFSET);
    volatile uint32_t *out3 = (uint32_t *)(AES_BASE_ADDR + AES_OUT3_OFFSET);

volatile uint8_t output[16];
int main() {
    uart_init(&uart0,(uint32_t *) 0x10008010); // addres of 3rh slave HORNET wb
    
    //while(1){ // main infinite loop 
   
    //aes_encrypt(in,output);
    *in0 = 0x14523689;
    *in1 = 0x22323689;
    *in2 = 0x51423689;
    *in3 = 0x97523689;
    *in4 = 0x1;
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
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");
    __asm__ volatile("nop");


    s0= *out0;
    s1= *out1;
    s2= *out2;
    s3= *out3;

    //uart_transmit_string(&uart0, "yusuf", 5);
    uart_transmit_string(&uart0, (char *)(s0 &0xff), 1);
    //};
    return 0;
}
void mti_handler() {}//empty handlers 
void exc_handler() {}
void mei_handler() {}
void msi_handler() {}

void fast_irq0_handler() {
}
void fast_irq1_handler() {} // empty handler