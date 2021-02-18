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
		free(count);
		free(pval);
		free(pOp);
		fatalError("Inputted string is empty.");
	}

	while(currentString != NULL){

		if(tokenType(currentString) == TOK_INT){
			currentString = consumeInt(currentString, pval);
			if(count[0] == MAX_STACK){
				free(count);
				free(pval);
				free(pOp);
				fatalError("Too many elements in the stack currently.");
			}
			stackPush(numberStack, count, pval[0]);	
		}
	
		else if(tokenType(currentString) == TOK_OP){
			currentString = consumeOp(currentString, pOp);
			if(count[0] < 2){
				free(count);
				free(pval);
				free(pOp);
				fatalError("Not enough elements in stack for operation.");
			}
			right = stackPop(numberStack, count);
			left = stackPop(numberStack, count);
			stackPush(numberStack, count, evalOp(pOp[0], left, right));
		}
	
		else if(tokenType(currentString) == TOK_UNKNOWN){
			free(count);
			free(pval);
			free(pOp);
			fatalError("Inputted an invalid string.");
		}

		currentString = skipws(currentString);
	}

	if(count[0] == 1){
		long answer = stackPop(numberStack, count);
		free(count);
		free(pval);
		free(pOp);	
		return answer;
	}

	else if(count[0] > 1){
		free(count);
		free(pval);
		free(pOp);
		fatalError("Too many items in the stack.");
	}

	else if(count[0] == 0){
		free(count);
		free(pval);
		free(pOp);
		fatalError("No items in the stack.");
	}
}
