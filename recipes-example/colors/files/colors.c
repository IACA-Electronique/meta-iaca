#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/fb.h>
#include <time.h>
#include <string.h>

int main() {
    int fb_fd;
    struct fb_var_screeninfo vinfo;
    struct fb_fix_screeninfo finfo;
    long screensize;
    unsigned char *fbp = NULL;
    
    // Open framebuffer device
    fb_fd = open("/dev/fb0", O_WRONLY);
    if (fb_fd == -1) {
        perror("Error opening /dev/fb0");
        return 1;
    }
    
    // Get fixed screen info
    if (ioctl(fb_fd, FBIOGET_FSCREENINFO, &finfo)) {
        perror("Error reading fixed screen info");
        close(fb_fd);
        return 1;
    }
    
    // Get variable screen info
    if (ioctl(fb_fd, FBIOGET_VSCREENINFO, &vinfo)) {
        perror("Error reading variable screen info");
        close(fb_fd);
        return 1;
    }
    
    // Calculate screen size
    screensize = vinfo.xres * vinfo.yres * vinfo.bits_per_pixel / 8;
    
    // Map framebuffer to memory
    fbp = (unsigned char *)malloc(screensize);
    if (!fbp) {
        perror("Error allocating memory");
        close(fb_fd);
        return 1;
    }
    
    // Seed random number generator
    srand(time(NULL));
    
    // Main loop - change color every 2 seconds
    while (1) {
        // Generate random RGB values
        unsigned char r = rand() % 256;
        unsigned char g = rand() % 256;
        unsigned char b = rand() % 256;
        
        // Fill entire framebuffer with the random color
        unsigned int pixel_value;
        
        if (vinfo.bits_per_pixel == 32) {
            // 32-bit color: ARGB format
            pixel_value = (0xFF << 24) | (r << 16) | (g << 8) | b;
            for (unsigned int i = 0; i < screensize; i += 4) {
                *(unsigned int *)(fbp + i) = pixel_value;
            }
        } else if (vinfo.bits_per_pixel == 16) {
            // 16-bit color: RGB565 format
            pixel_value = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3);
            for (unsigned int i = 0; i < screensize; i += 2) {
                *(unsigned short *)(fbp + i) = pixel_value;
            }
        } else {
            fprintf(stderr, "Unsupported bits per pixel: %d\n", vinfo.bits_per_pixel);
            break;
        }
        
        // Write to framebuffer
        lseek(fb_fd, 0, SEEK_SET);
        if (write(fb_fd, fbp, screensize) == -1) {
            perror("Error writing to framebuffer");
            break;
        }
        
        printf("Color changed to RGB(%d, %d, %d)\n", r, g, b);
        
        // Sleep for 2 seconds
        sleep(2);
    }
    
    // Cleanup
    free(fbp);
    close(fb_fd);
    return 0;
}