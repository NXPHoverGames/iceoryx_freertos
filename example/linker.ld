/* Copyright 2018-2023 Piotr Grygorczuk <grygorek@gmail.com>
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
*/
__RAM_BASE       = 0x60000000;
__RAM_SIZE       = 0x10000000;
__RW_DATA_SIZE   = 0x00100000;
__ZI_DATA_SIZE   = 0x000F0000;
__STACK_SIZE     = 0x00010000;
__HEAP_SIZE      = 0x00008000;
__UND_STACK_SIZE = 0x00001000;
__ABT_STACK_SIZE = 0x00001000;
__SVC_STACK_SIZE = 0x00001000;
__IRQ_STACK_SIZE = 0x00001000;
__FIQ_STACK_SIZE = 0x00001000;

/*----------------------------------------------------------------------------*/

/*--------------------- TTB Configuration ------------------------------------
//
// <h> TTB Configuration
//   <i> The TLB L1 contains 4096 32-bit entries and must be 16kB aligned
//   <i> The TLB L2 entries are placed after the L1 in the MMU config
//   <o0> TTB Base Address <0x0-0xFFFFFFFF:0x4000>
//   <o1> TTB Size (in Bytes) <0x0-0xFFFFFFFF:8>
// </h>
 *----------------------------------------------------------------------------*/
__TTB_BASE   =    0x60000000; /* not valid - TLB is not used */
__TTB_SIZE   =    0x00005000;


MEMORY
{
  ROM (rx)   : ORIGIN = __RAM_BASE + __RAM_SIZE, LENGTH = __RAM_SIZE
  L_TTB (rw) : ORIGIN = __TTB_BASE, LENGTH = __TTB_SIZE
  RAM (rwx)  : ORIGIN = __RAM_BASE, LENGTH = __RAM_SIZE
}

GROUP (
  "libstdc++_nano.a"
  "libsupc++_nano.a"
  "libc_nano.a"
  "libm.a"
  "libgcc.a"
  "crtbegin.o"
  "crtend.o" 
  "crti.o"
  "crtn.o"
)


ENTRY(Reset_Handler)

SECTIONS
{
    .text :
    {

        Image$$VECTORS$$Base = .;
        * (RESET)
        KEEP(*(.isr_vector))
        Image$$VECTORS$$Limit = .;

        *(SVC_TABLE)
        *(.text*)

        KEEP(*(.init))
        KEEP(*(.fini))

        /* .ctors */
        *crtbegin.o(.ctors)
        *crtbegin?.o(.ctors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
        *(SORT(.ctors.*))
        *(.ctors)

        /* .dtors */
        *crtbegin.o(.dtors)
        *crtbegin?.o(.dtors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
        *(SORT(.dtors.*))
        *(.dtors)

        Image$$RO_DATA$$Base = .;
        *(.rodata*)
        Image$$RO_DATA$$Limit = .;

        KEEP(*(.eh_frame*))
    } > ROM

    /*
     * for exception handling/unwind - some Newlib functions (in common
     * with C++ and STDC++) use this. 
     */
    .ARM.extab : ALIGN(8) 
    {
      __extab_start = .;
        *(.ARM.extab* .gnu.linkonce.armextab.*)
      __extab_end = .;
    } > ROM

    .ARM.exidx :
    {
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
    } > ROM


    .copy.table :
    {
        . = ALIGN(4);
        __copy_table_start__ = .;
        LONG (__etext)
        LONG (__data_start__)
        LONG (__data_end__ - __data_start__)
        __copy_table_end__ = .;
    } > ROM

    .zero.table :
    {
        . = ALIGN(4);
        __zero_table_start__ = .;
        LONG (__bss_start__)
        LONG (__bss_end__ - __bss_start__)
        __zero_table_end__ = .;
    } > ROM

    __etext = .;
        
    .ttb :
    {
        Image$$TTB$$ZI$$Base = .;
        . += __TTB_SIZE;
        Image$$TTB$$ZI$$Limit = .;
    } > L_TTB

     __data_load_start__ = ALIGN(4);
    .data : AT (__etext)
    {
        Image$$RW_DATA$$Base = .;
        __data_start__ = .;
        *(vtable)
        *(.data*)
        Image$$RW_DATA$$Limit = .;

        . = ALIGN(4);
        /* preinit data */
        PROVIDE (__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE (__preinit_array_end = .);

        . = ALIGN(4);
        /* init data */
        PROVIDE (__init_array_start = .);
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
        PROVIDE (__init_array_end = .);


        . = ALIGN(4);
        /* finit data */
        PROVIDE (__fini_array_start = .);
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array))
        PROVIDE (__fini_array_end = .);

        . = ALIGN(4);
        /* All data end */
        __data_end__ = .;

    } > RAM

    
    .bss ALIGN(0x400):
    {
        Image$$ZI_DATA$$Base = .;
        __bss_start__ = .;
        *(.bss*)
        *(COMMON)
        __bss_end__ = .;
        Image$$ZI_DATA$$Limit = .;
        __end__ = .;
        end = __end__;
    } > RAM

/* Taken from https://wiki.segger.com/Thread-Local_Storage */
     __tbss_load_start__ = ALIGN(__bss_end__ , 4);
     .tbss ALIGN(__bss_end__ , 4) (NOLOAD) : AT(ALIGN(__bss_end__ , 4))
     {
       __tbss_start__ = .;
       *(.tbss .tbss.*)
     }
     __tbss_end__ = __tbss_start__ + SIZEOF(.tbss);
     __tbss_size__ = SIZEOF(.tbss);
     __tbss_load_end__ = __tbss_end__;

     __tdata_load_start__ = ALIGN(__data_load_start__ + SIZEOF(.data) , 4);
     .tdata ALIGN(__tbss_end__ , 4) : AT(ALIGN(__data_load_start__ + SIZEOF(.data) , 4))
     {
       __tdata_start__ = .;
       *(.tdata .tdata.*)
     }
     __tdata_end__ = __tdata_start__ + SIZEOF(.tdata);
     __tdata_size__ = SIZEOF(.tdata);
     __tdata_load_end__ = __tdata_load_start__ + SIZEOF(.tdata);

     .tdata_run ALIGN(__tbss_end__ , 4) (NOLOAD) :
     {
       __tdata_run_start__ = .;
     }
     __tdata_run_end__ = __tdata_run_start__ + SIZEOF(.tdata);
     __tdata_run_size__ = __tdata_run_end__ - __tdata_run_start__;
     __tdata_run_load_end__ = __tdata_run_end__;

/* #if defined(__HEAP_SIZE) && (__HEAP_SIZE > 0)    */
    .heap (NOLOAD):
    {
        . = ALIGN(8);
        Image$$HEAP$$ZI$$Base = .;
        . += __HEAP_SIZE;
        Image$$HEAP$$ZI$$Limit = .;
        __HeapLimit = .;
    } > RAM  
/* #endif */

    .stack (NOLOAD):
    {
        . = ORIGIN(RAM) + LENGTH(RAM) - __STACK_SIZE - __FIQ_STACK_SIZE - __IRQ_STACK_SIZE - __SVC_STACK_SIZE - __ABT_STACK_SIZE - __UND_STACK_SIZE;
        . = ALIGN(8);
        
        __StackTop = .;
        Image$$SYS_STACK$$ZI$$Base = .;
        . += __STACK_SIZE;
        Image$$SYS_STACK$$ZI$$Limit = .;
        __stack = .;

        Image$$FIQ_STACK$$ZI$$Base = .;
        . += __FIQ_STACK_SIZE;
        Image$$FIQ_STACK$$ZI$$Limit = .;

        Image$$IRQ_STACK$$ZI$$Base = .;
        . += __IRQ_STACK_SIZE;
        Image$$IRQ_STACK$$ZI$$Limit = .;

        Image$$SVC_STACK$$ZI$$Base = .;
        . += __SVC_STACK_SIZE;
        Image$$SVC_STACK$$ZI$$Limit = .;

        Image$$ABT_STACK$$ZI$$Base = .;
        . += __ABT_STACK_SIZE;
        Image$$ABT_STACK$$ZI$$Limit = .;

        Image$$UND_STACK$$ZI$$Base = .;
        . += __UND_STACK_SIZE;
        Image$$UND_STACK$$ZI$$Limit = .;
        
    } > RAM
}
