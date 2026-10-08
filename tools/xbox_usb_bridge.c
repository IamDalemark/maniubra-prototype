// Local USB input reader for the original Xbox One controller (045e:02d1).
// GIP packet layout and wake sequence are documented in Linux's xpad driver:
// https://github.com/torvalds/linux/blob/master/drivers/input/joystick/xpad.c
#include <arpa/inet.h>
#include <libusb.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

static volatile sig_atomic_t running = 1;

static void stop(int signum) {
    (void)signum;
    running = 0;
}

static bool initialize_controller(libusb_device_handle *device) {
    unsigned char power[] = {0x05, 0x20, 0x00, 0x01, 0x00};
    unsigned char led[] = {0x0a, 0x20, 0x01, 0x03, 0x00, 0x01, 0x14};
    unsigned char auth[] = {0x06, 0x20, 0x02, 0x02, 0x01, 0x00};
    unsigned char *steps[] = {power, led, auth};
    int sizes[] = {(int)sizeof(power), (int)sizeof(led), (int)sizeof(auth)};
    for (int i = 0; i < 3; i++) {
        int sent = 0;
        int result = libusb_interrupt_transfer(device, 0x01, steps[i], sizes[i], &sent, 1000);
        if (result != LIBUSB_SUCCESS || sent != sizes[i]) return false;
    }
    return true;
}

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    char *end = NULL;
    long port = strtol(argv[1], &end, 10);
    if (*end != '\0' || port < 1024 || port > 65535) return 2;

    signal(SIGTERM, stop);
    signal(SIGINT, stop);
    int socket_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (socket_fd < 0) return 3;
    struct sockaddr_in target = {0};
    target.sin_family = AF_INET;
    target.sin_port = htons((uint16_t)port);
    inet_pton(AF_INET, "127.0.0.1", &target.sin_addr);

    libusb_context *context = NULL;
    if (libusb_init(&context) != LIBUSB_SUCCESS) {
        close(socket_fd);
        return 4;
    }
    while (running) {
        libusb_device_handle *device = libusb_open_device_with_vid_pid(context, 0x045e, 0x02d1);
        if (device == NULL) {
            sleep(1);
            continue;
        }
        if (libusb_claim_interface(device, 0) != LIBUSB_SUCCESS) {
            libusb_close(device);
            sleep(1);
            continue;
        }
        if (initialize_controller(device)) {
            unsigned char message[22] = {'M', 'U', 'B', '1', 0x20};
            while (running) {
                unsigned char packet[64] = {0};
                int length = 0;
                int result = libusb_interrupt_transfer(device, 0x81, packet, sizeof(packet), &length, 100);
                if (result != LIBUSB_SUCCESS && result != LIBUSB_ERROR_TIMEOUT) break;
                if (result == LIBUSB_SUCCESS && length >= 18 && packet[0] == 0x20) {
                    memcpy(message + 4, packet, 18);
                }
                // Input reports arrive on change; repeat the last state as a heartbeat.
                sendto(socket_fd, message, sizeof(message), 0,
                       (struct sockaddr *)&target, sizeof(target));
            }
        }
        libusb_release_interface(device, 0);
        libusb_close(device);
        if (running) sleep(1);
    }
    libusb_exit(context);
    close(socket_fd);
    return 0;
}
