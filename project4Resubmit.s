        .text
        .align 2
        .global main


main:
    stp     x30, x19, [sp, -16]!
    stp     d8, d9, [sp, -16]!
    stp     d10, d11, [sp, -16]!
    stp     x20, x21, [sp, -16]!
    stp     x22, x23, [sp, -16]!
    stp     x24, x25, [sp, -16]!
    // stores the registers onto stack

    ldr     x22, =levels
    // initialize levels into register
    bl      initscr
    // this intializes the screen to be used by ncurses
    ldr     d8, pi              // d8 holds pi's value
    fadd    d8, d8, d8          
    // multiply pi by 2 and store it in d8 ( to get 2 * pi)
    fsub    d9, d8, d8
    // phase (d9) = 0
    fsub    d10, d8, d8
    // theta (d10) = 0
    ldr     x25, =COLS
    ldr     w25, [x25]
    scvtf   d0, w25
    // loads COLS, and casts to double
    fdiv    d11, d8, d0
    // results in d11 being assigned increment  (tpi / COLS)

top:
    bl      erase
    // erases screen
    fadd    d9, d9, d11
    // increases phase by increment
    mov     w20, wzr
    // sets line counter to 0

sinner:
    ldr     x24, =LINES
    ldr     w24, [x24]
    cmp     w20, w24
    // checks if line count is greater than or equal to LINES of terminal, if so branches to bottom
    bge     bottom
    fsub     d10, d8, d8
    // theta (d10) = 0
    mov     w21, wzr
    // sets column counter to 0

tinner:
    ldr     x25, =COLS
    ldr     w25, [x25]
    cmp     w21, w25
    // checks if column count is greater than or equal to COLS of terminal, if so branches to binner
    bge     binner
    
// this is all to calculate ((sin(phase + theta) + 1.0) / 2.0 * 10);
    
    fadd    d0, d9, d10
    // d0 is phase + theta
    bl      sin
    // sin(phase + theta)
    fmov    d1, 1.0
    // d1 is 1.0
    fadd    d0, d0, d1
    // (sin(phase + theta) + 1.0)
    fmov    d1, 2.0
    fdiv    d0, d0, d1
    // sin(phase + theta) + 1.0) / 2.0
    fmov    d1, 10.0
    // d1 is 10
    fmul    d0, d0, d1
    // ((sin(phase + theta) + 1.0) / 2.0 * 10)
    fcvtzs  w23, d0
    // changes from double to int

    mov     w0, w20
    mov     w1, w21
    uxtb    x23, w23
    ldrb    w2, [x22, x23]
    // sets up 3 parameters of mvaddch
    // first parameter is line #
    // second parameter is column #
    // third parameter is correct character in levels using intensity as an offset
    bl      mvaddch
    // mvaddch(l, c, levels[intensity])

    fadd    d10, d10, d11
    // adds increment to theta
    mov     w0, 1
    add     w21, w21, w0
    // adds 1 to column counter
    b       tinner

binner:
    mov     w0, 1
    add     w20, w20, w0
    // adds 1 to line counter
    b       sinner

bottom:
    
    ldr     x0, =stdscr
    ldr     x0, [x0]
    mov     w1, wzr
    mov     w2, wzr
    // sets up 3 parameters for box
    // first parameter is stdscr
    // second parameter is 0
    // third parameter is 0

    bl      box
    // writes a box

    bl      refresh
    // refreshes the chars on the screen
    b       top
    // loop

    bl      endwin
    // closes ncurses terminal window


    // restores stack
    ldp     x24, x25, [sp], 16
    ldp     x22, x23, [sp], 16
    ldp     x20, x21, [sp], 16
    ldp     d10, d11, [sp], 16
    ldp     d8, d9, [sp], 16
    ldp     x30, x19, [sp], 16

    mov     x0, xzr
    ret

        .data

pi:         .double      3.14159265359
levels:     .asciz      " .:-=+*#%@"

        .end
