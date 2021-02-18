#include <stdio.h>
#include <stdlib.h>
#include "cPostfixCalc.h"

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
long eval(const char *s) {
	long numberStack[MAX_STACK];
	char *currentString;
	long *count, *pval, left, right;
	int *pOp;

	currentString = skipws(s);
	count = (long *)malloc(sizeof(long));
	pval = (long *)malloc(sizeof(long));
	pOp = (int *)malloc(sizeof(int));

	count[0] = 0;

	if(currentString == NULL){
		fatalError("Inputted string is empty.");
	}

	while(currentString != NULL){

		if(tokenType(currentString) == TOK_INT){
			currentString = consumeInt(currentString, pval);
			stackPush(numberStack, count, pval[0]);	
		}
	
		else if(tokenType(currentString) == TOK_OP){
			currentString = consumeOp(currentString, pOp);
			right = stackPop(numberStack, count);
			left = stackPop(numberStack, count);
			stackPush(numberStack, count, evalOp(pOp[0], left, right));
		}
	
		else if(tokenType(currentString) == TOK_UNKNOWN){
			fatalError("Inputted an invalid string.");
		}

		currentString = skipws(currentString);
	}

	if(count[0] == 1){
		return stackPop(numberStack, count);
	}

	else if(count[0] > 1){
		fatalError("Too many items in the stack.");
	}

	else if(count[0] == 0){
		fatalError("No items in the stack.");
	}
}
