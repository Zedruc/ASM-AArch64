# $@ = target name
# $< = first prerequisite of target
# $^ = all prerequisites of target

main: main.o zero_buffer.o
	ld -o main $^

main.o: main.s
	as -o main.o main.s

zero_buffer.o: zero_buffer.s
	as -o zero_buffer.o zero_buffer.s

debug:
	as -g -o main.o main.s
	as -g -o zero_buffer.o zero_buffer.s
	ld -o main main.o zero_buffer.o
	gdb ./main
