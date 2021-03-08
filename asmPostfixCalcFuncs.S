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
        movb $0, %r10b            
        movb $0, %r11b

        addb (%rdi), %r11b

        cmpb $58, %r11b
        jl .LsecondComparison
        
.LtopTwo:
        cmpb $43, %r11b
        je .LequalToOp
        cmpb $45, %r11b
        je .LequalToOp
        cmpb $42, %r11b
        je .LequalToOp
        cmpb $47, %r11b
        je .LequalToOp
         
        jmp .LequalToUnknown

.LsecondComparison:
        cmpb $47, %r11b
        jg .LequalToDigit
        jmp .LtopTwo

.LequalToDigit:
        movl $TOK_INT, %eax
        jmp .LreturnStatement

.LequalToOp:
        movl $TOK_OP, %eax
        jmp .LreturnStatement

.LequalToUnknown:
       movl $TOK_UNKNOWN, %eax
      
.LreturnStatement:
       addq $8, %rsp 
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
	subq $8, %rsp
	movq $0, %r10
	movq $0, %r11
	movq $0, %r12
	movq $0, %r13
	movq $0, (%rsi, %r12, 8)

.LcheckIfNumber:
	cmpb $58, (%rdi, %r12, 1)
	jl .LsecondConsumeIntComparison
	jmp .Lfinished	

.LsecondConsumeIntComparison:
	cmpb $47, (%rdi, %r12, 1)
	jg .LcontinueWhileLoop
	jmp .Lfinished

.LcontinueWhileLoop:
	movq $0, %r11
	movb $48, %r13b

.LsecondWhileLoop:
	cmpb %r13b, (%rdi, %r12, 1)
	jne .Lincrement
	movq (%rsi, %r12, 8), %rax
	movq $10, %r12
	mulq %r12
	movq $0, %r12
	movq %rax, (%rsi, %r12, 8)

	subq $48, %r13
	addq %r13, (%rsi, %r12, 8)
	addq $1, %rdi
	jmp .LcheckIfNumber

.Lincrement:
	incb %r13b
	jmp .LsecondWhileLoop

.Lfinished:
	movq %rdi, %rax
	addq $8, %rsp
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
        subq $8, %rsp
        movq $0, %r10 
          
        movb (%rdi, %r10, 1), %r11b
        movb %r11b, (%rsi, %r10, 1)
        
        addq $1, %rdi 
        movq %rdi, %rax

        addq $8, %rsp
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
