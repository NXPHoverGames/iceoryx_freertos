Experimental Eclipse iceoryx for FreeRTOS port
==============================================

This is a repository which demonstrates how to build and run [Eclipse
iceoryx](https://github.com/eclipse-iceoryx/iceoryx) for an embedded platform
with the FreeRTOS kernel. 

In particular, we are using the Arm Versatile Express board with the Cortex-A9
CPU, running in QEMU system emulator.

There are two extra dependencies, the
[FreeRTOS+POSIX](https://freertos.org/FreeRTOS-Plus/FreeRTOS_Plus_POSIX/index.html)
library and the [C++ FreeRTOS GCC](https://github.com/grygorek/FreeRTOS_cpp11)
library. The former is needed to implement various POSIX functions used in
iceoryx (such as unnamed semaphores and `clock_gettime`), while the latter is
used to implement threading primitives from the standard C++ library (such as
`std::thread` and `std::mutex`). Both of the these, and Eclipse iceoryx itself,
are linked here as submodules, so please clone with `--recursive`.

The build is only tested with the GNU Arm Embedded Toolchain 10.3, while the
execution is only tested with QEMU 6.2.0 (default `qemu-system-arm` apt package
version on Ubuntu 22).

## Example

The demo application in the directory `example` is provided. It is based on the
`singleprocess` demo in iceoryx, since we also need to initialize RouDi inside
the application process, there are no process in the embedded environment.

Next, it initializes a publisher and a subscriber in separate threads and
periodically writes and reads a message. It is also printing log messages to
UART, where QEMU is forwarding them to its output.

Finaly, it demonstrates how to implement and enable a custom iceoryx logger and
error handler. These are needed, since the logger output should be redirected
to UART, while the error handler should disable interrupts and enter an
infinite loop (the usual embedded assert failure handler procedure).

# Build and execute in docker

We supply a (Dockerfile)[Dockerfile] to provide a reliable build environment.
To build the docker image, run the following:
```
docker build . -t iox_freertos:0.1
```

And then to run the docker continer and execute the already compiled binary in QEMU:
```
docker run iox_freertos:0.1
```

Dont worry about the QEMU warnings, those are just uninitialized devices such
as an audio card. After those warnings, the expected output is:
```
Starting main ...
Configuring RouDi memory pool...
1970-01-01 00:00:00.043 [Debug]: Trying to reserve lu bytes in the shared memory [iceoryx_mgmt]
1970-01-01 00:00:00.056 [Debug]: Acquired lu bytes successfully in the shared memory [iceoryx_mgmt]
1970-01-01 00:00:00.069 [Debug]: Registered memory segment 0x60819218 with size lu to id lu
1970-01-01 00:00:00.080 [Debug]: Trying to reserve lu bytes in the shared memory [iceoryx_freertos]
1970-01-01 00:00:00.080 [Debug]: Acquired lu bytes successfully in the shared memory [iceoryx_freertos]
1970-01-01 00:00:00.082 [Debug]: Roudi registered payload data segment 0x6082dbc0 with size lu to id lu
Running RouDi...
1970-01-01 00:00:00.189 [Warn ]: Runnning RouDi on 32-bit architectures is not supported! Use at your own risk!
1970-01-01 00:00:00.341 [Debug]: Trying to reserve lu bytes in the shared memory [iox_np_roudi]
1970-01-01 00:00:00.343 [Debug]: Acquired lu bytes successfully in the shared memory [iox_np_roudi]
Initializing posh runtime...
1970-01-01 00:00:00.541 [Warn ]: Running applications on 32-bit architectures is not supported! Use at your own risk!
1970-01-01 00:00:00.545 [Debug]: Trying to reserve lu bytes in the shared memory [iox_np_freertosExample]
1970-01-01 00:00:00.545 [Debug]: Acquired lu bytes successfully in the shared memory [iox_np_freertosExample]
1970-01-01 00:00:00.592 [Debug]: Registered new application freertosExample
Initializing publisher thread...
Initializing subscriber thread...
1970-01-01 00:00:00.700 [Debug]: Created new PublisherPort for application 'freertosExample' with service description 'Service: Free, Instance: RTOS, Event: Demo'
Publisher created!
1970-01-01 00:00:00.738 [Debug]: Created new SubscriberPort for application 'freertosExample' with service description 'Service: Free, Instance: RTOS, Event: Demo'
Subscriber created!
Sample 000000000 published!
Sample 000000000 received!
Sample 000000001 published!
Sample 000000001 received!
Sample 000000002 published!
Sample 000000002 received!
Sample 000000003 published!
Sample 000000003 received!
```

## Debugging

It can be very useful to debug changes while running the QEMU inside the
container. For that, we need to mount a local build directory into the
container. Furthermore, we can use the `-s` and `-S` options of QEMU, which
open a gdb-server on port 1234 and break the CPU immediately after start:
```
cd iceoryx_freertos
docker run -ti -v$(pwd):/iceoryx_freertos_mounted -p 1234:1234 --rm iox_freertos:0.1 bash
cd /iceoryx_freertos_mounted/build-example
qemu-system-arm -M vexpress-a9 -m 500M -nographic -kernel iox_freertos_example -s -S
```

Then, the following can be done to attach a local gdb to the remote QEMU:
```
gdb-multiarch -tui iox_freertos_example
(gdb) target remote localhost:1234
```

# Limitations

Eclipse iceoryx is using thread-local storage (the `thread_local` keyword) for
logger implementation and the polymorphic handler type. This is not
well-supported with FreeRTOS, because the compiler doesnt understand FreeRTOS
tasks. For now, I worked around this by setting the `-mtp=soft` GCC option,
implementing a trivial `__aeabi_read_tp` hook and adding the `.tbss` and
`.data` sections to the linker based on
https://wiki.segger.com/Thread-Local_Storage.

However it always uses the same address of thread-local storage. So, we can
successfully compile and execute but it doesnt function correctly, it behaves
rather like normal static storage. I think this could be implemented properly
by using the FreeRTOS-native thread-local storage
(https://www.freertos.org/thread-local-storage-pointers.html) inside the
`__aeabi_read_tp` implementation. It would be a very interesting feature and
could be merged into https://github.com/grygorek/FreeRTOS_cpp11.

Furthermore, I found that we must not use position independent code (PIC) when
building iceoryx libraries. PIC is usually always desired on Linux, but it
relies on some patching of addresses by the runtime linker when the ELF is
loaded into memory, which is not available in the embedded toolchain. The issue
manifested by some `nullptr` function addresses if they are used as function
pointers. Disabling PIC resolved this issue.

I think that PIC can be used, but we are just missing some configuration or
linker setting. Maybe we are just missing the global offset table. It is a bit
strange that the linker doesnt patch everything when it links the final ELF
file, because it knows the final memory layout, no idea why...

# License

Please refer to (LICENSE)[./LICENSE] file for details on the licenses.
