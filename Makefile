.SUFFIXES: .o .c
.PHONY: all options prog valmem dist clean graph

UNAME		:= $(shell uname)

ifeq ($(UNAME), Darwin)
COMPILER	:= $(shell bash -c 'ls /usr/local/bin/ | grep -E -x "gcc-[0-9]+"')
else
COMPILER	:= gcc
endif

PROGRAM    	= program
TESTPROG   	= test-$(PROGRAM)
VERSION    	= 0.0.0.0
AUTSCRIPT	= automation	# name of automation scrip if present
MAIN		= main			# name of main file if different
SRC        	= $(wildcard *.c)
OBJ        	= $(SRC:.c=.o)
OUTFILES	= $(wildcard *.out)
INFILES		= $(wildcard *.in)
TEST_FRAME 	= Unity			# name of test framework if present
TESTFSRC	= $(wildcard $(TEST_FRAME)/*.c)
TESTFOBJ	= $(OBJ) $(TESTFSRC:.c=.o)
MDS        	= Makefile
CC		= $(COMPILER)
OPTFLAGS	= -Ofast -march=native -mtune=native # Og - debugging
WARNFLAGS	= -Wall -Wextra -Wpedantic --pedantic-errors # -Werror \
			  -Wfatal-errors -Wduplicated-branches -Walloc-zero \
			  -Wdeclaration-after-statement
CFLAGS     	= -std=c99 -g $(WARNFLAGS) $(OPTFLAGS)
LDLIBS     	= -lm
VALFLAGS	= --track-origins=yes --leak-check=full --leak-resolution=high -s
INFILE		= $(shell bash -c 'read -p "File name: " file; echo $$file')

all: options $(PROGRAM) $(TESTPROG)
options:
	@echo "PROGRAM = $(PROGRAM).o"
	@echo "TEST PROGRAM = $(TESTPROG).o"
	@echo $(PROGRAM) build options:
	@echo "CC      = $(CC)"
	@echo "CFLAGS  = $(CFLAGS)"
	@echo "LDLIBS  = $(LDLIBS)"
$(PROGRAM): $(filter-out $(TESTPROG).o, $(OBJ))
	$(CC) $(CFLAGS) -o $@ $^ $(LDLIBS)
$(TESTPROG): $(filter-out $(MAIN).o, $(TESTFOBJ))
	$(CC) $(CFLAGS) -o $@ $^ $(LDLIBS)
.c.o:
	$(CC) $(CFLAGS) -c $<
prog: options $(PROGRAM)
	./$(PROGRAM)
check: options $(TESTPROG)
	./$(TESTPROG)
script: $(PROGRAM) #$(TESTPROG)
	./$(AUTSCRIPT).sh
valmem: options $(PROGRAM)
	valgrind $(VALFLAGS) ./$(PROGRAM) < $(INFILE)
dist: clean
	mkdir -p -- "$(PROGRAM)-$(VERSION)"
	cp -R -- $(MDS) *.c *.h $(AUTSCRIPT).sh $(INFILES)\
				$(TEST_FRAME) "$(PROGRAM)-$(VERSION)"
	tar -cf - "$(PROGRAM)-$(VERSION)" | \
		bzip2 -c > "$(PROGRAM)-$(VERSION).tar.bz2"
	rm -rf -- "$(PROGRAM)-$(VERSION)"
clean:
	@rm -f $(PROGRAM) $(TESTPROG) $(OBJ) $(PROGRAM)-$(VERSION).tar.bz2
	@rm -f $(OUTFILES) $(GRAPHFILES)
