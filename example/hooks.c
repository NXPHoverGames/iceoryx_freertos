// Copyright 2023 NXP

#include <sys/time.h>

#include "FreeRTOS_POSIX.h"
#include "FreeRTOS_POSIX/time.h" // clock_gettime

int _gettimeofday(struct timeval *tv, void *tzvp) {
  struct timespec ts;
  clock_gettime(0, &ts);
  if (tv) {
    tv->tv_sec = ts.tv_sec;
    tv->tv_usec = ts.tv_nsec / 1000;
  }
  return 0;
}

// This is needed by the `remove` POSIX function used in iceoryx
int _unlink(const char *path) {
  (void)path;
  return 0;
}

/* thread_local hook, enabled thanks to -mtp=soft */
/* Please refer to https://wiki.segger.com/Thread-Local_Storage */
void *__aeabi_read_tp(void) {
  extern char __tbss_start__;
  return &__tbss_start__ - 8;
}
