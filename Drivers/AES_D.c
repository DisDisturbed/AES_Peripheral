#include "AES_H.h"
#include <stdint.h>

static inline void aes_start_encrypt(const uint8_t data[16]) {
    *((volatile uint32_t *)(AES_BASE_ADDR + AES_IN0_OFFSET)) =
        ((uint32_t)data[0] << 24) | ((uint32_t)data[1] << 16) |
        ((uint32_t)data[2] << 8)  | ((uint32_t)data[3]);

    *((volatile uint32_t *)(AES_BASE_ADDR + AES_IN1_OFFSET)) =
        ((uint32_t)data[4] << 24) | ((uint32_t)data[5] << 16) |
        ((uint32_t)data[6] << 8)  | ((uint32_t)data[7]);

    *((volatile uint32_t *)(AES_BASE_ADDR + AES_IN2_OFFSET)) =
        ((uint32_t)data[8] << 24) | ((uint32_t)data[9] << 16) |
        ((uint32_t)data[10] << 8) | ((uint32_t)data[11]);

    *((volatile uint32_t *)(AES_BASE_ADDR + AES_IN3_OFFSET)) =
        ((uint32_t)data[12] << 24) | ((uint32_t)data[13] << 16) |
        ((uint32_t)data[14] << 8) | ((uint32_t)data[15]);

    *((volatile uint32_t *)(AES_BASE_ADDR + AES_CTRL_OFFSET)) = AES_CTRL_START_MASK;
}

static inline void aes_read_output(volatile uint8_t output[16]) {
    volatile uint32_t *out0 = (uint32_t *)(AES_BASE_ADDR + AES_OUT0_OFFSET);
    volatile uint32_t *out1 = (uint32_t *)(AES_BASE_ADDR + AES_OUT1_OFFSET);
    volatile uint32_t *out2 = (uint32_t *)(AES_BASE_ADDR + AES_OUT2_OFFSET);
    volatile uint32_t *out3 = (uint32_t *)(AES_BASE_ADDR + AES_OUT3_OFFSET);

    uint32_t w0 = *out0;
    uint32_t w1 = *out1;
    uint32_t w2 = *out2;
    uint32_t w3 = *out3;
    output[0]  = (w3 >> 24) & 0xFF;
    output[1]  = (w3 >> 16) & 0xFF;
    output[2]  = (w3 >> 8)  & 0xFF;
    output[3]  = (w3)       & 0xFF;

    output[4]  = (w2 >> 24) & 0xFF;
    output[5]  = (w2 >> 16) & 0xFF;
    output[6]  = (w2 >> 8)  & 0xFF;
    output[7]  = (w2)       & 0xFF;

    output[8]  = (w1 >> 24) & 0xFF;
    output[9]  = (w1 >> 16) & 0xFF;
    output[10] = (w1 >> 8)  & 0xFF;
    output[11] = (w1)       & 0xFF;

    output[12] = (w0 >> 24) & 0xFF;
    output[13] = (w0 >> 16) & 0xFF;
    output[14] = (w0 >> 8)  & 0xFF;
    output[15] = (w0)       & 0xFF;
}
static inline void aes_wait_ready(void) {
    volatile uint32_t *status = (volatile uint32_t *)(AES_BASE_ADDR + AES_STATUS_OFFSET);
    while ((*status & AES_STATUS_READY_MASK) == 1) {
        __asm__ volatile("nop");
    }
}
void aes_encrypt(const uint8_t input[16], volatile uint8_t output[16]){
    aes_start_encrypt(input);
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
    aes_wait_ready();
    aes_read_output(output);

}