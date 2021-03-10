        .text
        .align      2
        .global     main

// x0 has argv as an int
firstmalloc:  stp     x20, x30, [sp, -16]!         // to protect values from main
        str     x22, [sp, -16]!                    // ^^^
        // for allocating and storing new's addr
        mov     w20, w0                      // stores the int for after allocation (because currently in x0)
        mov     x0, 16                       // puts 16 bytes into x0 (parameter) for malloc function call
        bl      malloc                       // malloc allocates using parameter x0 (in bytes)
        mov     x22, x0                      // x22 holds address to update head later
        // for updating head_ptr address
        adr     x1, head_ptr                 // connects global variable to a register for updating
        str     x22, [x1]                    // stores the address of the new node into head_ptr's location
        // for filling first new node
        mov     x1, 0                        // moves desired element of struct into x1 to store on next line
        str     x1, [x0]                     // next_ptr is 0 because this is first malloc
        mov     w1, w20                      // moves the int that was previously stored to w1
        str     w1, [x0, 8]                  // moves over 8 bytes and inserts the payload given by argv into new node
        b end
        end:
                ldr     x22, [sp], 16            // to restore main's values before returning
                ldp     x20, x30, [sp], 16       // ^^^
                ret
// x0 has argv as an int, is negative
remove:         stp     x20, x30, [sp, -16]! // backs up main's values to stack
                stp     x21, x22, [sp, -16]! // ^^^
                stp     x23, x24, [sp, -16]! // ^^^
                mov     x1, -1               // stores -1 into x1, for sign conversion
                mul     x0, x1, x0           // multiplies int by negative to result in positive for comparison

                mov     w20, w0              // holds changed int in safe place
                adr     x1, head_ptr             // gets reference to head_ptr
                ldr     x21, [x1]                // gets node addr from head_ptr
        findint:
                ldr     x21, [x1]                // gets node addr from head_ptr
                cbz     x1, exit
                ldr     x22, [x21, 8]            // increments the size of the next, dereferences to get payload
                ldr     x23, [x21]               // now x23 holds the next of the curr_node
                // check if curr_node payload == desired removed payload
                cmp     x20, x22
                beq     delete
                str     x23, [x1]
                b       findint
        delete: 
                adr     x3, head_ptr
                ldr     x4, [x3]
                cmp     x21, x4
                beq     ishead
                ldr     x24, [x21, -16]
                
                str     x23, [x24]
                mov     x0, x21
                bl      free
                b       exit
        ishead:     
                str     x23, [x3]
                mov     x0, x21
                bl      free
                b       exit

        exit:
                ldp     x23, x24, [sp], 16
                ldp     x21, x22, [sp], 16
                ldp     x20, x30, [sp], 16
                ret

// x0 has argv as an int
insertmalloc:   str     x30, [sp, -16]!      // to protect values from main
                stp     x20, x21, [sp, -16]! // ^^^
                stp     x22, x23, [sp, -16]! // ^^^
                stp     x25, x27, [sp, -16]! // ^^^
                // for setting up loop and protecting int input
                mov     w20, w0                  // stores int in safe place for allocation later
                adr     x1, head_ptr             // gets reference to head_ptr
                ldr     x21, [x1]                // gets node addr from head_ptr
        findspot:
                ldr     x21, [x1]                // loads curr_node from head_ptr
                // stores curr_node's payload in x22, next in x23
                ldr     x22, [x21, 8]            // increments the size of the next, dereferences to get payload
                ldr     x23, [x21]               // now x23 holds the next of the curr_node
                // compare the curr_node's payload to the insert payload
                cmp     x0, x22                  // checks curr_node payload against insert payload
                ble     beforeat                 // this branch represents inserting before the curr_node
                // checks if curr_node's next is null (0)
                cbz     x23, after               // branches if next is 0, because represents a 'insertafter'
                str     x23, [x1]                // stores curr_node's next into x1, to increment incase function loops
                ldr     x4, [x1]                 // node goes into x4
                ldr     x22, [x4, 8]             // loads next's payload for next comparison
                // check if next's payload is greater than insert int
                cmp     x0, x22                  // compares curr_node's next's payload to the insert payload
                bgt     findspot                 // if the next node's payload is smaller than insert payload, loop again
        beforeat:
                // stores desired bytes in x0, passes x0 into malloc
                mov     x0, 16                   // puts 16 bytes into x0 (parameter) for malloc function call
                bl      malloc                   // malloc allocates using parameter x0 (in bytes)
                // places curr_node addr into new_node's next
                str     x21, [x0]                // places curr_node addr into new_node's next
                mov     w1, w20                  // moves the int that was previously stored to w1
                str     w1, [x0, 8]              // moves over 8 bytes and inserts the payload given by parameter into new node
                // check if curr_ptr is the head
                adr     x27, head_ptr            // gets reference to head_ptr 
                ldr     x25, [x27]               // loads x25 with head_node
                cmp     x25, x21                 // compares curr_node to head_node
                beq     currishead               // branches if curr_node = head_node (to update addr of head_node)
                // need to check previous node to see if exists/needing updating
                ldr     x1, [x21, -16]           // gets next (addr) of last node
                cbz     x1, lastloop             // checks if prev_node's addr exists, if not, nothing to update
                // below represents case when there is a prev_node
                ldr     x5, [x1]                 // uses prev_node, dereferences to get prev_node's next
                str     x0, [x5]                 // puts x0 (addr of newnode), into x1 (lastnodes next)
                // gets head_node ready to return
                adr     x27, head_ptr            // gets reference to head_ptr
                ldr     x1, [x27]                // loads x1 with node of head_ptr
                mov     x0, x1                   // returns address of new headnode to be stored upon program exit
                b       lastloop                 // branch to end for restoring stack
        currishead:
                // stores new node_ptr x0 in x27 (updates head_node held by head_ptr)
                str     x0, [x27]
                // gets head_node ready to return
                adr     x27, head_ptr            // gets reference to head_ptr
                ldr     x1, [x27]                // loads x1 with node of head_ptr
                mov     x0, x1                   // returns address of new headnode to be stored upon program exit
                b       lastloop                 // branch to end for restoring stack
        after:
                // stores desired bytes in x0, passes x0 into malloc
                mov     x0, 16                   // puts 16 bytes into x0 (parameter) for malloc function call
                bl      malloc                   // malloc allocates using parameter x0 (in bytes)
                // stores malloc address into curr pointer's next
                str     x0, [x21]                // stores new_node addr into curr_node's next (because inserted after last node)
                // used for updating contents of new_node
                mov     x3, 0                    // puts desired next (0, since going to be last_node) into x3
                str     x3, [x0]                 // stores 0 as new_node's next
                mov     w1, w20                  // moves saved int to w1               
                str     w1, [x0, 8]              // moves size of next_ptr (8 bytes), stores int at new_node payload
                mov     x0, x25                  // moves head_node (x25) to x0 to be returned
                b       lastloop                 // branch to end for restoring stack
        lastloop: 
                ldp     x25, x27, [sp], 16       // to restore main's values before returning
                ldp     x22, x23, [sp], 16       // ^^^
                ldp     x20, x21, [sp], 16       // ^^^
                ldr     x30, [sp], 16            // ^^^
                ret
// nothing passed in to print        
print:  str     x30, [sp, -16]!                  // protects main's values
        stp     x20, x21, [sp, -16]!             // ^^^
        // gets node held by head_ptr
        adr     x21, head_ptr                    // reference to global variable head_ptr
        ldr     x20, [x21]                       // loads head_node from head_ptr
        // sets up initial print
        adr     x0, head_address                 // loads reference to head_address format into x0
        mov     x1, x20                          // moves the head_node addr to x1 for print
        bl      printf                           // prints head_node statement
        second:
                adr     x0, node_info            // loads reference to node_info format into x0
                cbz     x20, final               // checks if curr_node is null (0)
                ldr     w2, [x20, 8]             // loads the curr_node's payload into w2 for print
                mov     x1, x20                  // moves the curr_node's addr to x1
                ldr     x3, [x20]                // moves curr_node's next into x3
                bl      printf                   // prints node info line (with addr, payload, and next)
                ldr     x20, [x20]               // updates curr_node (x20) by loading it with curr_node's next
                b       second                   // loops (until no more nodes) (which is caused by the curr_node being 0)
        final:
                ldp     x20, x21, [sp], 16       // restores main's values from stack
                ldr     x30, [sp], 16            // ^^^
                ret

main:   stp     x20, x30, [sp, -16]!         // must protect stack since function will be called
        mov     x20, x1                      // stores argv[]
        mainloop:      
                ldr     x21, [x20, 8]!                   // dereferences argv[] to get a char *
                cbz     x21, outloop                     // sees if char * is empty, loops to print if is
                // all for converting argv to int
                mov     x0, x21                      // move curr_char * (which is x1) to x0 for integer conversion
                bl      atoi                         // should make the argv instance sent in into an int before storing
                mov     x21, x0                      // moves int to x21 again for storage
                
                mov     x5, 0
                cmp     x21, x5                     // compares curr int to 0 to see if negative
                blt     remove
                // will be dedicated to finding if negative, and taking appropriate steps
        //        mov     x1, 0
        //        cmp     x1, x0
        //        bge     negative 

                // used for getting and checking if head_node from head_ptr is null
                adr     x0, head_ptr                 // gets reference to head_ptr
                ldr     x24, [x0]                    // loads the head_node from head_ptr
                mov     x0, x21                      // moves int back to x0, incase branch to first, and then function call
                cbz     x24, first                   // checks if address is null (which means first malloc)
                // head is already occupied, search for where to insert
                
                bl      insertmalloc                 // calls insert malloc, passes in int (x0)
                mov     x25, x0                      // this is the head node's address, very important during print statement portion
                adr     x1, head_ptr
                str     x25, [x1]
                b       mainloop
                
        first:
                bl      firstmalloc                  // calls insert malloc, passes in int (x0)
                // update head if head changed with new malloc
                mov     x25, x0                      // this is the head node's address, very important during print statement portion
                adr     x1, head_ptr                    
                str     x25, [x1]
                b       mainloop
        outloop:
                bl      print
                b       endprog
        endprog:
                ldp     x20, x30, [sp], 16
                mov     x0, xzr
                ret     
        .data
head_ptr:       .space  8, 0
head_address:	.asciz		"head points to: %x\n"
node_info:	.asciz		"node at %8x contains payload: %lu next: %8x\n"
bad_malloc:	.asciz		"malloc() failed\n"
        .end


        // when mallocing, place size of allocation in x0, then call bl malloc






/*
        adr     x1, levels
        // index 0 check
        cmp     w0, 0
        beq     31f
        // index 1 check
        cmp     w0, 1
        beq     32f
        // index 2 check
        cmp     w0, 2
        beq     33f
        // index 3 check
        cmp     w0, 3
        beq     34f
        // index 4 check
        cmp     w0, 4
        beq     35f
        // index 5 check
        cmp     w0, 5
        beq     36f
        // index 6 check
        cmp     w0, 6
        beq     37f
        // index 7 check
        cmp     w0, 7
        beq     38f
        // index 8 check
        cmp     w0, 8
        beq     39f
        // index 9 check
        cmp     w0, 9
        beq     40f
        // all checks/branches for what char of levels is needed
// index 0
31:
        ldr     x2, [levels]
        // gets proper char from levels[0], stores in x2 for 'mvaddch' function call
        b       45f
// index 1
32:
        ldr     x2, [levels, 1]
        // gets proper char from levels[1], stores in x2 for 'mvaddch' function call
        b       45f
// index 2
33:
        ldr     x2, [levels, 2]
        // gets proper char from levels[2], stores in x2 for 'mvaddch' function call
        b       45f
// index 3
34:
        ldr     x2, [levels, 3]
        // gets proper char from levels[3], stores in x2 for 'mvaddch' function call
        b       45f
// index 4
35:
        ldr     x2, [levels, 4]
        // gets proper char from levels[4], stores in x2 for 'mvaddch' function call
        b       45f
// index 5
36:
        ldr     x2, [levels, 5]
        // gets proper char from levels[5], stores in x2 for 'mvaddch' function call
        b       45f
// index 6
37:
        ldr     x2, [levels, 6]
        // gets proper char from levels[6], stores in x2 for 'mvaddch' function call
        b       45f
// index 7
38:
        ldr     x2, [levels, 7]
        // gets proper char from levels[7], stores in x2 for 'mvaddch' function call
        b       45f
// index 8
39:
        ldr     x2, [levels, 8]
        // gets proper char from levels[8], stores in x2 for 'mvaddch' function call
        b       45f
// index 9
40:
        ldr     x2, [levels, 9]
        // gets proper char from levels[9], stores in x2 for 'mvaddch' function call
        b       45f
45:     // represents point where level's char is held in x2
 */