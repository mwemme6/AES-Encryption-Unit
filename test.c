/******************************************************************************
# test.c  - A test C programm
#
# Part of the Rudi-RV32I project
#
# See https://github.com/hamsternz/Rudi-RV32I
#
# MIT License
#
###############################################################################
#
# Copyright (c) 2020 Mike Field
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
******************************************************************************/
#include <stdint.h>
//#include <stdio.h>
#include <stddef.h>
#define KEY_MAX_LENGTH 16

//char text[] = "Hello world!\r\n";
//char az[] = "Text ";  
//char bz[] = " characters long\r\n";

char encryption_key[KEY_MAX_LENGTH];
char message[KEY_MAX_LENGTH];
char encrypted_message[KEY_MAX_LENGTH];
uint8_t key_index;
uint8_t message_index;

volatile char *serial_tx        = (char *)0xE0000000;
volatile char *serial_tx_full   = (char *)0xE0000004;
volatile char *serial_rx        = (char *)0xE0000008;
volatile char *serial_rx_empty  = (char *)0xE000000C;
volatile int  *gpio_value       = (int  *)0xE0000010;
volatile int  *gpio_direction   = (int  *)0xE0000014;

volatile int *aes_key = (int *)0xE0000040; // Adresse für AES-Nachricht
volatile int *aes_msg = (int *)0xE0000050; // Adresse für AES-Nachricht
volatile int *aes_ctrl = (int *)0xE0000060; // Adresse für AES-Steuerregister
volatile int *aes_status = (int *)0xE0000064; // Adresse für AES-Statusregister
volatile int *aes_result = (int *)0xE0000070; // Adresse für AES-Ergebnisregister


//function declarations
int puts(char *s);
int putchar(int c);

int send_test (int t) {
    *aes_key = t;
    return t;
}

void print_hex(uint8_t val) {
    char hex[] = "0123456789ABCDEF";
    putchar(hex[val >> 4]);
    putchar(hex[val & 0x0F]);
}

void print_result(uint8_t *result, int length) {
    for (int i = 0; i < length; i++) {
        print_hex(result[i]);
    }
    putchar('\n'); // Zeilenumbruch am Ende
}

int aes_send_key(const uint8_t* key) {
    if (key == NULL) {
        return -1; // Fehler: ungültiger Zeiger
    }

    for (int i = 0; i < 4; i++) {
        aes_key[i] = (key[4 * i]) |
                     (key[4 * i + 1] << 8) |
                     (key[4 * i + 2] << 16) |
                     (key[4 * i + 3] << 24);
    }

    return 0; // Erfolg
}
//diese Funktion kann ich vllt auch zusammenpacken mit aes_send_key
int aes_send_message(const uint8_t* msg) {
    if (msg == NULL) {
        return -1; // Fehler: ungültiger Zeiger
    }

    for (int i = 0; i < 4; i++) {
        aes_msg[i] = (msg[4 * i]) |
                     (msg[4 * i + 1] << 8) |
                     (msg[4 * i + 2] << 16) |
                     (msg[4 * i + 3] << 24);
    }

    return 0; // Erfolg
}

 
int aes_start(void) {
    if (aes_ctrl == NULL) {
        return -1;  // Fehler: ungültiger Zeiger
    }

    *aes_ctrl = 1;  // Start-Bit setzen
    //puts("AES started");
        // Kurzer Software-Delay
    for(volatile int i = 0; i < 100; i++);  // Dummy-Schleife zum Warten

    *aes_ctrl = 0;

    return 0;       // Erfolg
}

int aes_wait_done(void) {
    //puts("inside aes_wait_done");
    if (aes_status == NULL) {
      return -1;  // Fehler: ungültiger Zeiger
    }
    //puts("aes_status is not NULL");
    
    while ((*aes_status & 1) == 0) {
        //puts("Waiting for AES...");
    }
    //puts("AES done");
    return 0; // Erfolg
}


int aes_read_result(uint8_t* output) {
    if (output == NULL) {
        return -1; // Fehler: ungültiger Speicherzeiger
    }

    for (int i = 0; i < 4; i++) {
        uint32_t val = aes_result[i];
        output[4 * i]     = val & 0xFF;
        output[4 * i + 1] = (val >> 8) & 0xFF;
        output[4 * i + 2] = (val >> 16) & 0xFF;
        output[4 * i + 3] = (val >> 24) & 0xFF;
        //puts("AES result read");
    }

    return 0; // Erfolg
}


int aes_encrypt_block(const uint8_t *key, const uint8_t *plaintext, uint8_t *output) {
    if (key == NULL || plaintext == NULL || output == NULL) {
        return -1; // Fehler: ungültiger Zeiger
    }

    if (aes_send_key(key) != 0) {
        return -2; // Fehler beim Senden des Schlüssels
    }

    if (aes_send_message(plaintext) != 0) {
        return -3; // Fehler beim Senden des Klartexts
    }

    if (aes_start() != 0) {
        return -4; // Fehler beim Starten der AES-Einheit
    }

    if (aes_wait_done() != 0) {
        return -5; // AES-Funktion wurde nicht fertig
    }

    if (aes_read_result(output) != 0) {
        return -6; // Fehler beim Einlesen des Ergebnisses
    }

    return 0; // Erfolg
}



int getchar(void) {

  // Wait until status is zero 
  while(*serial_rx_empty) {
  }

  // Output character
  return *serial_rx;
}

int putchar(int c) {

  // Wait until status is zero 
  while(*serial_tx_full) {
  }

  // Output character
  *serial_tx = c;
  return c;
}

int puts(char *s) {
    int n = 0;
    while(*s) {
      putchar(*s);
      s++;
      n++;
    } 
    return n;
}

int mylen(char *s) {
    int n = 0;
    while(*s) {
      s++;
      n++;
    } 
    return n;
}

int test_program(void) {
    while (1) {
        //send_test(0x12345678); // Beispielaufruf

        //uint8_t key[16] = "1234567890ABCDEF";
        //aes_send_key(key);

        //puts("Enter the encryption key (max 16 characters): ");
        uint8_t key[16] = "1234567890ABCDEF";
        uint8_t msg[16] = "SecretMessage123";
        uint8_t result[16];
        puts("test");
        aes_encrypt_block(key, msg, result);
                /*puts("\nEncrypted Message: ");*/
        
        //for(volatile int i = 0; i < 10000; i++);  // Dummy-Schleife zum Warten
        // for (int i = 0; i < 16; i++) {
        //     putchar(result[i]);
        // }
        print_result(result, 16);
        //puts("Enter the encryption key (max 16 characters): ");
    }
  return 0;
}