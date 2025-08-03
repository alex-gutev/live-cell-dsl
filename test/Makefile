DART=fvm dart
CC=$(DART) run live_cell
SEARCH_PATH=../modules
ARGS=-m $(SEARCH_PATH)

TESTS=generated/single_argument_computed_cell.g.dart \
	generated/multi_argument_computed_cell.g.dart \
 	generated/complex_expressions.g.dart \
 	generated/simple_function.g.dart \
 	generated/nary_function.g.dart \
 	generated/multi_expression_function.g.dart \
 	generated/function_closure.g.dart \
 	generated/nested_function_closure.g.dart \
 	generated/lexical_scope.g.dart \
 	generated/lexical_scope_function_arguments.g.dart \
 	generated/higher_order_function.g.dart \
 	generated/higher_order_function_closure_local.g.dart \
 	generated/higher_order_function_closure.g.dart \
 	generated/higher_order_function_closure_scope.g.dart \
 	generated/recursion.g.dart \
 	generated/tail_recursion.g.dart \
 	generated/recursion_fibonacci.g.dart \
 	generated/mutual_recursion.g.dart

generated/%.g.dart: sources/%.lc
	$(CC) ${ARGS} -o $@ $<

all: $(TESTS)

clean:
	rm generated/*.g.dart