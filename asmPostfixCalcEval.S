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

numStack: .space (8 * MAX_STACK)
count: .space (4)
pval: .space (8)

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

	movq %rax, %r8              /* r8 will hold our current string (callee saved)*/
	movq $numStack, %r9         /* r9 will be the pointer to our stack (callee saved)*/
	movq $count, %r10           /* r10 will contain information about the stack size (callee saved)*/

	cmp $0, %r8                 /* check if current string is empty (only terminator char)*/
	je .LemptyString            /* call error for empty string*/

.LiterateThroughString:
	movq %r8, %rdi              /* making current string a first parameter*/
	call tokenType              /* returns token type of first char in current string*/
	
	cmp $TOK_INT, %rax          /* jump to tokenInt if first char is an int*/
	je .LtokenInt

	cmp $TOK_OP, %rax           /* jump to tokenOp if first char is an OP*/
	je .LtokenOp

	cmp $TOK_UNKNOWN, %rax      /* jump to tokenUnknown if first char is int*/
	je .LtokenUnknown

.LtokenInt:
	movq %r8, %rdi              /* load current string as first parameter*/
	pushq %r8                   /* push r8 into stack for storage*/
	pushq %r9                   /* push r9 into stack for storage*/
	pushq %r10                  /* push r10 into stack for storage*/
	call consumeInt             /* note that pval = %rsi*/
	popq %r10                   /* return previous r10*/
	popq %r9                    /* return previous r9*/
	popq %r8                    /* return previous r8*/
	movq %rsi, %r12             /* move pval to temp register (caller saved)*/
	movq %rax, %r8              /* update the current string*/
	
	movq %r9, %rdi              /* stack pointer is the first parameter*/
	movq %r10, %rsi             /* stack counter is the second parameter*/
	movq %r12, %rdx             /* the value returned by consumeInt is third parameter*/
	pushq %r8                   /* push r8 into stack for storage*/
        pushq %r9                   /* push r9 into stack for storage*/
        pushq %r10                  /* push r10 into stack for storage*/
	call stackPush              /* push new integer into stack*/
	popq %r10                   /* return previous r10*/
        popq %r9                    /* return previous r9*/
        popq %r8                    /* return previous r8*/
	movq %rdi, %r9              /* update stack register with updated stack*/
	movq %rsi, %r10             /* update stack counter with updated counter*/
	
	jmp .LcontinueLoop

.LtokenOp:
	movq %r8, %rdi              /* load current string as first parameter*/
	pushq %r8                   /* push r8 into stack for storage*/
        pushq %r9                   /* push r9 into stack for storage*/
        pushq %r10                  /* push r10 into stack for storage*/
	call consumeOp              /* note that pOp = %rsi*/
	popq %r10                   /* return previous r10*/
        popq %r9                    /* return previous r9*/
        popq %r8                    /* return previous r8*/
	pushq %rsi                  /* push pOp onto stack for storage*/
	movq %rax, %r8              /* update the current string*/

	movq %r9, %rdi              /* load the stack pointer into the first parameter*/
	movq %r10, %rsi             /* load the counter into the second parameter*/
	pushq %r8                   /* push r8 into stack for storage*/
        pushq %r9                   /* push r9 into stack for storage*/
        pushq %r10                  /* push r10 into stack for storage*/
	call stackPop               /* Note: pops left operand*/
	popq %r10                   /* return previous r10*/
        popq %r9                    /* return previous r9*/
        popq %r8                    /* return previous r8*/
	movq %rdi, %r9              /* update stack*/
	movq %rsi, %r10             /* update stack pointer*/
	pushq %rax                  /* save the popped value into the stack for storage*/

	movq %r9, %rdi              /* load the stack pointer into the first parameter*/
        movq %r10, %rsi             /* load the counter into the second parameter*/
	pushq %r8                   /* push r8 into stack for storage*/
        pushq %r9                   /* push r9 into stack for storage*/
        pushq %r10                  /* push r10 into stack for storage*/
        call stackPop               /* Note: pops right operand*/
	popq %r10                   /* return previous r10*/
        popq %r9                    /* return previous r9*/
        popq %r8                    /* return previous r8*/
	movq %rdi, %r9              /* update stack*/
        movq %rsi, %r10             /* update stack pointer*/
        pushq %rax                  /* push the popped value into the stack for storage*/

	popq %rsi                   /* load left operand into second parameter*/
	popq %rdx                   /* load right operand into third parameter*/
	popq %rdi                   /* load previous operator into first parameter*/
	pushq %r8                   /* push r8 into stack for storage*/
        pushq %r9                   /* push r9 into stack for storage*/
        pushq %r10                  /* push r10 into stack for storage*/
	call evalOp                 /* evaluate once*/
	popq %r10                   /* return previous r10*/
        popq %r9                    /* return previous r9*/
        popq %r8                    /* return previous r8*/
	movq %rax, %r11             /* load the result from evalOp into the temp register r11*/

	movq %r9, %rdi              /* load the stack pointer into the first parameter*/
	movq %r10, %rsi             /* load the counter into the second parameter*/
	movq %r11, %rdx             /* load the result from evalOp into the third parameter*/
	pushq %r8                   /* push r8 into stack for storage*/
        pushq %r9                   /* push r9 into stack for storage*/
        pushq %r10                  /* push r10 into stack for storage*/
	call stackPush              /* push the result from the previous evaluation*/
	popq %r10                   /* return previous r10*/
        popq %r9                    /* return previous r9*/
        popq %r8                    /* return previous r8*/
	movq %rdi, %r9              /* update stack*/
        movq %rsi, %r10             /* update stack pointer*/

	jmp .LcontinueLoop

.LtokenUnknown:
	jmp .LinvalidString

.LcontinueLoop:
	movq %r8, %rdi              /* make current string into first parameter*/
	pushq %r8                   /* push r8 into stack for storage*/
        pushq %r9                   /* push r9 into stack for storage*/
        pushq %r10                  /* push r10 into stack for storage*/
	call skipws                 /* get rid of leading spaces in first current string*/
	popq %r10                   /* return previous r10*/
        popq %r9                    /* return previous r9*/
        popq %r8                    /* return previous r8*/
	movq %rax, %r8              /* properly load the new current string without leading spaces*/
	cmp $0, %r8                 /* check if current string is empty (only terminator char)*/
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
	cmp $1, %r10                /* checks if there is only one thing in the stack*/
	jg .LoverflowStack          /* multiple things on stack, return error*/
	jl .LemptyStack             /* nothing in stack, return error*/
	                            /* if neither two are called, then we were given a valid string*/
	movq %r9, %rdi              /* move stack pointer to first parameter*/
	movq %r10, %rsi             /* move counter to second parameter*/
	call stackPop               /* note that %rax is now the final stack element*/
	addq $8, %rsp               /* fix the stack pointer*/ 
	ret

/* vim:ft=gas:
 */
