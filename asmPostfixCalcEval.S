/*
 * postfix calculator (assembly language version)
 * eval function implementation
 */

.equ TOK_INT, 0
.equ TOK_OP, 1
.equ TOK_UNKNOWN, 2

.equ MAX_STACK, 20

	.section .rodata
	
emptyString: .string "Inputted string is empty."
eStackMax: .string "Too many elements in the stack currently."
eStackMin: .string "Not enough elements in the stack for operation."
invalidString: .string "Inputted an invalid string."
overflowStack: .string "Too many items in the stack."
emptyStack: .string "No items in the stack."

/* TODO: add string constants and other read-only data here */

	.section .text

/*
 * eval - evaluate a postfix expression
 * Should directly or indirectly call fatalError if the expression is invalid.
 *
 * Params:
 *   s - C string containing a postfix expression
 *
 * Returns:
 *   the result of evaluating the expression
 */
	.globl eval
eval:
	subq $8, %rsp               /* align the stack pointer*/
	call skipws                 /* takes input string and removes leading whitespace*/

	movq %rax, %r12             /* r12 will hold our current string (callee saved)*/
	movq $0, %r13               /* r13 will be the pointer to our stack (callee saved)*/
	movq $0, %r14               /* r14 will contain information about the stack size (callee saved)*/

	cmp $0, %r12                /* check if current string is empty (only terminator char)*/
	je .LemptyString            /* call error for empty string*/

.LiterateThroughString:
	movq %r12, %rdi             /* making current string a first parameter*/
	call tokenType              /* returns token type of first char in current string*/
	
	cmp $TOK_INT, %rax          /* jump to tokenInt if first char is an int*/
	je .LtokenInt

	cmp $TOK_OP, %rax           /* jump to tokenOp if first char is an OP*/
	je .LtokenOp

	cmp $TOK_UNKNOWN, %rax      /* jump to tokenUnknown if first char is int*/
	je .LtokenUnknown

.LtokenInt:
	movq %r12, %rdi             /* load current string as first parameter*/
	call consumeInt             /* note that pval = %rsi*/
	movq %rsi, %r10             /* move pval to temp register (caller saved)*/
	movq %rax, %r12             /* update the current string*/
	
	movq %r13, %rdi             /* stack pointer is the first parameter*/
	movq %r14, %rsi             /* stack counter is the second parameter*/
	movq %r10, %rdx             /* the value returned by consumeInt is third parameter*/
	call stackPush
	
	jmp .LcontinueLoop

.LtokenOp:
	movq %r12, %rdi             /* load current string as first parameter*/
        call consumeOp              /* note that pOp = %rsi*/
	movq %rsi, %r10             /* move pOp to temp register (caller saved)*/
	movq %rax, %r12             /* update the current string*/

	movq %r13, %rdi             /* load the stack pointer into the first parameter*/
	movq %r14, %rsi             /* load the counter into the second parameter*/
	call stackPop               /* Note: pops right operand*/
	movq %rax, %r8              /* save the popped value into a temp register r8 (caller saved)*/

	movq %r13, %rdi             /* load the stack pointer into the first parameter*/
        movq %r14, %rsi             /* load the counter into the second parameter*/
        call stackPop               /* Note: pops left operand*/
        movq %rax, %r9              /* save the popped value into a temp register r9 (caller saved)*/

	movq %r10, %rdi             /* load previous operator into first parameter*/
	movq %r9, %rsi              /* load left operand into second parameter*/
	movq %r8, %rdx              /* load right operand into third parameter*/
	call evalOp
	movq %rax, %r10             /* load the result from evalOp into the temp register r10*/

	movq %r13, %rdi             /* load the stack pointer into the first parameter*/
	movq %r14, %rsi             /* load the counter into the second parameter*/
	movq %r10, %rdx             /* load the result from evalOp into the third parameter*/
	call stackPush

	jmp .LcontinueLoop

.LtokenUnknown:
	jmp .LinvalidString

.LcontinueLoop:
	movq %r12, %rdi             /* make current string into first parameter*/
	call skipws                 /* get rid of leading spaces in first current string*/
	movq %rax, %r12             /* properly load the new current string without leading spaces*/
	cmp $0, %r12                /* check if current string is empty (only terminator char)*/
	je .LendOfFunc              /* exit while loop if end of string is reached*/
	jmp .LiterateThroughString  /* otherwise, continue while loop*/

.LemptyString:
	movq $emptyString, %rdi     /* set appropriate error message*/
	call fatalError             /* call error*/

.LeStackMax:
        movq $eStackMax, %rdi       /* set appropriate error message*/
        call fatalError             /* call error*/

.LeStackMin:
        movq $eStackMin, %rdi       /* set appropriate error message*/
        call fatalError             /* call error*/

.LinvalidString:
        movq $invalidString, %rdi   /* set appropriate error message*/
        call fatalError             /* call error*/

.LoverflowStack:
        movq $overflowStack, %rdi   /* set appropriate error message*/
        call fatalError             /* call error*/

.LemptyStack:
        movq $emptyStack, %rdi      /* set appropriate error message*/
        call fatalError             /* call error*/

.LendOfFunc:
	cmp $1, %r14                /* checks if there is only one thing in the stack*/
	jl .LoverflowStack          /* multiple things on stack, return error*/
	jg .LemptyStack             /* nothing in stack, return error*/
	                            /* if neither two are called, then we were given a valid string*/
	movq %r13, %rdi             /* move stack pointer to first parameter*/
	movq %r14, %rsi             /* move counter to second parameter*/
	call stackPop               /* note that %rax is now the final stack element*/
	addq $8, %rsp               /* fix the stack pointer*/ 
	ret

/* vim:ft=gas:
 */
