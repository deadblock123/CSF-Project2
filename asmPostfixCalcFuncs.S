/*
 * postfix calculator (assembly language version)
 * function implementation
 */

.equ TOK_INT, 0
.equ TOK_OP, 1
.equ TOK_UNKNOWN, 2

.equ MAX_STACK, 20

	.section .rodata

eNegativeValue: .string "[Negative value], "
eStackMax: .string "[Stack is full], "
eStackMin: .string "[Stack is empty], "
sError: .string "ERROR: %s"
spaceArray: .string " "
spaceArray2: .string "\t"

charLibrary: .word 48, 49, 50, 51, 52, 53, 54, 55, 56, 57

.section .bss

/* TODO: add other string constants and other read-only data here */

	.section .text

/*
 * addPositive function (this is just an example function)
 */
	.globl addPositive
addPositive:
	subq $8, %rsp                /* align stack pointer */

	movq $0, %r10                /* let %r10 be 0 */
	cmpq %rdi, %r10              /* compare 1st param to 0 */
	jg .LaddPositiveNegativeOperand /* if less, it's negative */
	cmpq %rsi, %r10              /* compare 2nd param to 0 */
	jg .LaddPositiveNegativeOperand /* if less, it's negative */

	/* both operands are non-negative, do the addition */
	movq %rsi, %rax              /* move second parameter to %rax */
	addq %rdi, %rax              /* add first parameter to second */
	jmp .LaddPositiveDone

.LaddPositiveNegativeOperand:
	movq $eNegativeValue, %rdi
	call fatalError
9:	jmp 9b                       /* should not get here */

.LaddPositiveDone:
	/* the sum is now in %rax */
	addq $8, %rsp                /* restore stack pointer */
	ret

/*
 * fatalError - print an error message an exit with an exit code of 1.
 * Prints a message of the form "Error: <message text>" to standard output.
 * Does not return!
 *
 * Params:
 *   msg - description of the error which occurred
 */
	.globl fatalError
fatalError:
        subq $8, %rsp                /* align stack pointer */
        movq %rdi, %r10              /* move message to general purpose register*/
        movq $sError, %rdi           /* move the error message template to first parameter register*/
        movq %r10, %rsi              /* move error message to second parameter*/
        call printf                  /* call print*/

        addq $8, %rsp                /* restore stack pointer*/
        mov $1, %rdi                 /* moving exit code 1 to first parameter*/
        call exit                    /* call exit*/
	/* note that this function should not return */

/*
 * isSpace - tests a character code to determine whether or not it
 * is a space character.
 *
 * Params:
 *   c - an ASCII character code
 *
 * Returns:
 *   1 if c is a space or tab character, 0 otherwise
 *   (the function is allowed to also return 1 if c is a newline
 *   or carriage return, but it's only required to handle
 *   spaces and tabs)
 */
	.globl isSpace
isSpace:
        subq $8, %rsp               /* Align stack pointer*/
	cmp $32, %rdi               /* compares input to ascii value of space*/
        je .LequalToSpace           /* jumps if input is equal to space*/
        cmp $9, %rdi                /* compares input to ascii value of tab*/
        je .LequalToSpace           /* jumps if input is equal to tab*/
        jmp .LnotEqualToSpace	    /* if not equal to tab nor space, jump to end*/
        
.LequalToSpace:
        movq $1, %rax              /* returns 1 since input is a space*/
	jmp .Lreturn               /* jumps to end of function to return*/

.LnotEqualToSpace:
        movq $0, %rax              /* returns 0 since input is not a space*/
       
.Lreturn: 
        addq $8, %rsp              /* restore stack pointer*/
        ret

/*
 * isDigit - tests a character code to determine whether it is one
 * of the digits '0' through '9'
 *
 * Params:
 *   c - an ASCII character code
 *
 * Returns:
 *   1 if c is a digit, 0 otherwise
 */
	.globl isDigit
isDigit:
	subq $8, %rsp               /* align stack pointer*/
        cmp $58, %rdi               /* compares input to smallest value that is definitly not a number (9 is 57 in ascii)*/
        jl .LtestCase2              /* jumps becaus input may be a number*/
        jmp .LnotADigit             /* jumps because input may not be a number*/

.LtestCase2:
        cmp $47, %rdi               /* compares input to the largest value that is definitly not a number (o is 48 in ascii)*/
        jg .LisADigit               /* if between 58 and 47 then definitly a number*/
        jmp .LnotADigit             /* otherwise not a number*/

.LisADigit:
        movq $1, %rax               /* outputs 1 for number*/
        jmp .Lend                   /* returns function*/

.LnotADigit:
        movq $0, %rax              /* outputs 0 because not a function*/
      
.Lend:
        addq $8, %rsp              /* restores stack pointer*/
        ret
      

/*
 * skipws - skips any whitespace characters (as determined by isSpace)
 * at the beginning of a C character string.
 *
 * Params:
 *   s - pointer to a C character string
 *
 * Returns:
 *   pointer to the first non-space character in the string, or NULL
 *   if there are no non-space characters before the end of the string
 *   is reached
 */
	.globl skipws
skipws:
        subq $8, %rsp                /* align stack pointer*/
        movq $0, %r11                /* initialize r11 as an index variable*/

.LwhileSpace:
        cmpb $32,(%rdi, %r11, 1)     /* checks if we are pointing to a space char*/
        je .continueWhileLoop        /* if yes then continue the loop*/
        cmpb $9, (%rdi, %r11, 1)     /* checks if we are pointing to a tab char*/
        je .continueWhileLoop        /* if yes then continue the loop*/
	cmpb $0, (%rdi, %r11, 1)     /* checks if we have reached end of string*/
	je .noNoneSpace
        jmp .finishedSkipws          /* we have found a non space char*/

.continueWhileLoop:
        addq $1, %rdi                /* increase index by 1*/
        jmp .LwhileSpace             /* jump back to loop*/

.noNoneSpace:
	movq $0, %rax                /* make output equal to null*/
	addq $8, %rsp                /* fix stack pointer*/
        ret

.finishedSkipws:
	movq %rdi, %rax              /* move current string to output register*/
        addq $8, %rsp                /* fix stack pointer*/
        ret

/*
 * tokenType - return the token type (TOK_INT, TOK_OP, or TOK_UNKNOWN)
 * of the token at the beginning of given C character string.
 *
 * Params:
 *   s - nonempty C character string (which should not have any leading
 *       space characters)
 *
 * Returns:
 *   the token type
 */
	.globl tokenType
tokenType:
        subq $8, %rsp             /* align stack pointer*/
        movb $0, %r10b            /* set char r10b to 0 or null */
        movb $0, %r11b            /* set char r11b to 0 or null */

        addb (%rdi), %r11b        /* add the array[0] of the nonempty character string to the character */

        cmpb $58, %r11b           /* Compare the character to see if it's less then 58 if it is continue */
        jl .LsecondComparison
        
.LtopTwo:
        cmpb $43, %r11b  /* Compares the characters to each possible op 43, +, 45, -, 42, *, and 47, */
        je .LequalToOp   /* If it is then it is equal to an op */
        cmpb $45, %r11b
        je .LequalToOp
        cmpb $42, %r11b
        je .LequalToOp
        cmpb $47, %r11b
        je .LequalToOp
         
        jmp .LequalToUnknown /* Otherwise that one is unknown and move on down to replace the return variable to TOK_UNK */

.LsecondComparison:
        cmpb $47, %r11b /* Compare to see if it's greater than 47 if it is the it is a TOK_INT */
        jg .LequalToDigit /* Jump to it being equal to a digit */
        jmp .LtopTwo

.LequalToDigit:
        movl $TOK_INT, %eax /* Means return Token Int */
        jmp .LreturnStatement

.LequalToOp:
        movl $TOK_OP, %eax /* Means return Token Op */
        jmp .LreturnStatement

.LequalToUnknown:
       movl $TOK_UNKNOWN, %eax /* Means return Token Unknown */
      
.LreturnStatement:
       addq $8, %rsp /* realign stack pointer to ret correctly */
       ret
   

/*
 * consumeInt - consume one or more digit characters at the beginning
 * of given C character string, convert them to an integer value, and
 * store the integer value in the long (64 bit signed integer)
 * variable that pval points to.
 *
 * Params:
 *   s    - pointer to a nonempty C character string which should start
 *          with a digit character
 *   pval - points to a long variable where the converted integer value
 *          should be stored
 *
 * Returns:
 *   pointer to the first character in the string that is not a digit
 */
	.globl consumeInt
consumeInt:
	subq $8, %rsp /* Align stack pointer */
	movq $0, %r10 /* Initialize registers in order to refer to them later on */
	movq $0, %r11
	movq $0, %r12
	movq $0, %r13
	movq $0, (%rsi, %r12, 8) /* Set the variable equal to 0 */

.LcheckIfNumber:
	cmpb $58, (%rdi, %r12, 1) /* Compare the variables to see if it's equal to an int if it isn't an int get rid of it, finish the loop, simply just a checker for the loop */
	jl .LsecondConsumeIntComparison /* If it is go to the second check */
	jmp .Lfinished	

.LsecondConsumeIntComparison:
	cmpb $47, (%rdi, %r12, 1) /* Compare the variables to see if it's equal to an int if it isn't an int get rid of it, finish the loop, simply just a checker for the loop */
	jg .LcontinueWhileLoop /* If it is go to the continue you are set to continue on with the comparison */
	jmp .Lfinished /* Finish interem jump and complete the loop */

.LcontinueWhileLoop:
	movq $0, %r11 /* reset the register in order to start counting again */
	movb $48, %r13b /* start at 48 in order to get the digit properly from the character, remember char - 48 = the corresponding digit if it is a digit */

.LsecondWhileLoop:
	cmpb %r13b, (%rdi, %r12, 1) /* compare to see what the character is for %r13b in order to increase and completely move and traverse through the array slowly */
	jne .Lincrement /* If it isn't keep continuing on */
	movq (%rsi, %r12, 8), %rax /* return the new variable */
	movq $10, %r12 /* Multiply the %rax by %r12, getting the new variable corresponding to the number grabbed and increment the value already in there by 10 in order to read it correctly*/
	mulq %r12
	movq $0, %r12 /* Reset r12 in order to use it later on */
	movq %rax, (%rsi, %r12, 8) /* move the value new %rax into the long variable */
 
	subq $48, %r13 /* get the number of the new int and add it to the value of the multiplied %rax */
                       /* If you got 17 -> it would read the one first, [1], then multiply that by 10, [10], and then add the 7 [17] */
	addq %r13, (%rsi, %r12, 8) 
	addq $1, %rdi /* Add 1 to the rdi to check to see if you should continue with reading in the character string for multiple digits */
	jmp .LcheckIfNumber /* If not then you obviously have to go through this loop again with an increment ot %r13 because %r13 isn't equal to the values given */

.Lincrement:
	incb %r13b /* Continue moving with r13 to check which character it is */
	jmp .LsecondWhileLoop

.Lfinished:
	movq %rdi, %rax /* return the new string variable with the cut integer */
	addq $8, %rsp /* realign stack pointer */
	ret


/*
 * consumeOp - consume an operator character from the beginning of the
 * given C character string.
 *
 * Params:
 *   s - pointer to a nonempty C character string
 *   op - pointer
 to an int (32 bit signed integer) variable where the
 *        ASCII code of the first character of s should be stored
 *
 * Returns:
 *   a pointer to the second character of s
 */
	.globl consumeOp
consumeOp:
        subq $8, %rsp                   /* align stack pointer*/
          
        movb 0(%rdi), %r11b             /* first character moved to r11b*/
        movb %r11b, 0(%rsi)             /* move first character to first byte of rsi*/
        
        addq $1, %rdi                   /* delete first char in inputted string*/
        movq %rdi, %rax                 /* move new string to output*/

        addq $8, %rsp                   /* fix stack pointer*/
	ret

/*
 * stackPush - 
push a long (64 bit signed integer) value onto the stack.
 * Calls the fatalError function if the stack is full.
 * A full stack contains MAX_STACK (20) values.
 * If a value is successfully pushed on the stack, the count should
 * be incremented by 1.
 *
 * Params:
 *   stack - pointer to the beginning of the stack storage array
 *   count - pointer to a long variable storing the number of items
 *           currently on the stack
 *   val   - the value to push onto the stack
 *
 * Returns:
 *   nothing
 */
	.globl stackPush
stackPush:
        /* Argument Registers
         * %rdi -> stack - pointer to the stack storage array
         * %rsi -> pointer counter of elements in the stack
         * %rdx -> the value to push into the stack
         */
        subq $8, %rsp                /* align stack pointer*/

        movq (%rsi), %r10            /* move pointer counter to r10*/
         
        cmpq $20, %r10               /* find out if stack is full*/
        jge .LcallFatalError         /* if yes, then call error*/
        jmp .LstackPush              /* otherwise, proceed to the push*/

.LcallFatalError:
        movq $eStackMax, %rdi        /* load appropriate message into first parameter*/
        call fatalError              /* call error*/
9:      jmp 9b                       /* should not reach here*/

.LstackPush:
        movq %rdx, %r11              /* move the value that will be pushed to r11*/
        movq %r11, (%rdi, %r10, 8)   /* push the value into index specified by ""count*/
       ; addq $8, %rdi

        addq $1, %r10                /* increment count*/
        movq %r10, (%rsi)            /* return count to the second parameter*/

        addq $8, %rsp                /* fix stack pointer*/
	ret

/*
 * stackPop - pops a long (64 bit signed integer) value from the stack.
 * Calls the fatalError function if the stack is empty.
 * If a value is successfully popped off the stack, the count should
 * be decremented by 1.
 *
 * Params:
 *   stack - pointer to the beginning of the stack storage array
 *   count - pointer to a long variable storing the number of items
 *           currently on the stack
 *
 * Returns:
 *   the value popped from the stack
 */
	.globl stackPop
stackPop: 
        subq $8, %rsp                    /* align stack pointer*/
        
        movq (%rsi), %r10                /* move count into t10*/
        cmp $0, %r10                     /* check to see if stack is empty*/
        jle .LcallFatalMinError          /* if empty, call error*/
        jmp .LstackPop                   /* otherwise, proceed to the pop*/
 
.LcallFatalMinError:
        movq $eStackMin, %rdi            /* load appropriate message into first parameter*/
        call fatalError                  /* call error*/
9:      jmp 9b                           /* should not be reached*/

.LstackPop:
        subq $1, %r10                    /* decrement the count*/
        movq %r10, (%rsi)                /* return count to second parameter*/
 
        movq (%rdi, %r10, 8), %r11       /* get the final element in the stack and move it to r11*/
        movq %r11, %rax                  /* move the final element in the stack to output*/
        
        addq $8, %rsp                    /* fix stack pointer*/
	ret

/*
 * evalOp - evaluate a computation by applying an operator to two operands.
 *
 * Params:
 *   op - the operator ('+', '-', '*', or '/')
 *   left - the left operand
 *   right - the right operand
 *
 * Returns:
 *   the result of applying the operator to the operands
 */
	.globl evalOp
evalOp:
        subq $8, %rsp                  /* align atack pointer*/

        cmpl $43, %edi                 /* checks if operation is a plus sign*/
        je .LaddNumbers
 
        cmpl $45, %edi                 /* checks if operation is a minus sign*/
        je .LsubtractNumbers

        cmpl $42, %edi                 /* checks if operation is a multiplication sign*/
        je .LmultiplyNumbers
       
        cmpl $47, %edi                 /* checks if the operation is a division sign*/
        je .LdivideNumbers
        jmp .LsumCalculated            /* should not be reached*/

.LaddNumbers:
        movq %rsi, %rax                /* move left operand to output register*/
        addq %rdx, %rax                /* add left operand with right and have result in output*/
        jmp .LsumCalculated            /* complete function*/

.LsubtractNumbers:
        movq %rsi, %rax                /* move left operand to output register*/
        subq %rdx, %rax                /* subtract right from left and have result in output*/
        jmp .LsumCalculated            /* complete function*/

.LmultiplyNumbers:
        movq %rsi, %rax                /* move left operand to output register*/
        mulq %rdx                      /* multiply right and left and have result in output*/
        jmp .LsumCalculated            /* complete function */

.LdivideNumbers:
        movq %rsi, %rax                /* move left operand to output register*/
        movq %rdx, %r10                /* move right operand to r10*/
        movq $0, %rdx                  /* third parameter is equal to 0*/
        divq %r10                      /* divide left operand by right operand and store in output*/
        jmp .LsumCalculated            /* complete function*/

.LsumCalculated:
        addq $8, %rsp                  /* restore stack pointer*/
	ret

/* vim:ft=gas:
 */
