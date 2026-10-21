#include <unistd.h>

int main(int argc, char **argv) {
    (void)argc;
    execv("/usr/bin/joe", argv);
    return 127;
}
