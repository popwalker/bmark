#include <stdio.h>
#include <sys/time.h>

long long get_millisecond_timestamp() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (long long)tv.tv_sec * 1000 + (long long)tv.tv_usec / 1000;
}
