#ifndef AES_H_
#define AES_H_

#include <stdint.h>
#define AES_BASE_ADDR           0x10008030
#define AES_IN0_OFFSET          0x00 // Plaintext  (LSB)
#define AES_IN1_OFFSET          0x04
#define AES_IN2_OFFSET          0x08
#define AES_IN3_OFFSET          0x0C // Plaintext (MSB)

#define AES_CTRL_OFFSET         0x10 // Control  (Write 1 to start)
#define AES_STATUS_OFFSET       0x14 // Status  (Read 1 when ready)

#define AES_OUT0_OFFSET         0x18 // Ciphertext  (LSB)
#define AES_OUT1_OFFSET         0x1c
#define AES_OUT2_OFFSET         0x20
#define AES_OUT3_OFFSET         0x24 // Ciphertext  (MSB)

#define AES_CTRL_START_MASK     0x00000001
#define AES_STATUS_READY_MASK   0x00000001

void aes_encrypt(const uint8_t input[16], volatile uint8_t output[16]);

#endif // AES_H_