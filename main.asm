; Program Description: encrypt/decrypt a file using dynamiclly allocated memory

; Author:Austin lew

; Creation Date: 12/1/19

; Revisions: 

; Date:12/13/19              Modified by:

; Operating System:linux

; IDE/Compiler: sublime text, kdbg, build script
;
;Example program to execute 64-bit functions in Linux
;

;
;Include our external functions library functions
%include "./functions64.inc"
 
SECTION .data
 
	welcomePrompt		db	"Welcome to my 64 bit Program", 00h
			.len 		equ ($-welcomePrompt)
	goodbyePrompt		db	"Program ending, have a great day!", 00h
	errorPrompt 		db 	"error, program ending", 00h
			.len 		equ ($-errorPrompt)
	bytereadPrompt 		db 	"number of bytes read: ", 00h
			.len 		equ	($-bytereadPrompt)
	coutPrompt 			db 	"cout",0ah,0dh, 00h
	keyPrompt 			db	 "please enter a key to encrypt your file:", 00h
		.len	 		equ	($-keyPrompt)

	encryptPrompt 		db	 "Now encrypting/decrypting ",0h
	toPrompt 			db 	 " to ",0h


	
	bytecount 			dq	0h

	hexNumToPrint		dq	1234567890123456h
	decNumToPrint		dq	1234567890123456
	
	testRight			db	"Right", 00h
		.len 			equ ($-testRight)
	testLeft			db	"Left", 00h
	testCenter			db	"Center", 00h

	keycount 			db 	1

	total 				dq 0


 
SECTION .bss

	oldBottomAddress 	resq 1
	newBottomAddress 	resq 1

	sourceFileIO 		resq 1
	destinationFileIO 	resq 1
	inputFileD 			resq 1
	outputFileD 	 	resq 1
	keyBuffer 			resb 255
		.len	 		equ ($-keyBuffer)



SECTION     .text
	global  _start
     
_start:
;stack
; 	number of arguments [esp+8]
;	second argument 	[esp+16]
; 	first argument 		[esp+24]

	xor r13,r13
	;obtain current bottom of program
	mov rax, 0ch 						;sys_brk call
	mov rdi, 0	 						;return into rcx the current bottom of the program
	syscall 							;tickle the kernal
	mov [oldBottomAddress], rax 		;save the old bottom

	;allocate ffffh bytes
	mov rdi, rax 						;move the bottom address into rdi
	add rdi, 0ffffh 					;increase this by 100h bytes (increases the memory allocation for the program)
	mov rax, 0ch 						;sys_brk call
	syscall
	cmp rax, 0							;did reallocation work?
	jl 	Error1
	mov [newBottomAddress], rax 		;save the new bottom


TwoArgs:
	pop 	rax 						;number of command line arguments
	cmp 	rax, 3						;check that user typed exactly 2 arguments
	jne 	Error1

KeyEntry:

	push	welcomePrompt   			;welcomePrompt
	push 	welcomePrompt.len
	call	PrintText
	call	Printendl
	call	Printendl
	push 	keyPrompt					;prompt user for key
	push 	keyPrompt.len			
	call 	PrintText

	xor 	rbx,rbx						;clear scratch register
	push 	keyBuffer					;accept user input for key
	push 	keyBuffer.len
	call 	ReadText
	dec 	rax
	mov 	[keycount], rax				;put number of charaters into variable "keycount"

	push 	encryptPrompt
	call 	PrintString

	pop 	rax 						;path of main
	pop 	rax 						;path source
	mov 	[sourceFileIO], rax 		;save source path
	push 	rax 						;push rax onto stack for printString
	call 	PrintString					;print file name

	push 	toPrompt
	call 	PrintString

	pop 	rax ;path to destination
	mov 	[destinationFileIO], rax 
	push 	rax
	call 	PrintString					;print file name
	call 	Printendl





;/////////////////////////////////////////////////////////////////
OpenSource:
	mov 	rax, 2	 					;open file
	mov 	rdi, [sourceFileIO] 		;address of the file name
	mov 	rsi, 442h					;readbuffer into
	mov 	rdx, 2 						;open for read and write
	syscall		 						;poke kernal
	cmp 	rax, 0
	jl 		Error2
	mov 	[inputFileD], rax 			;save file discriptor
	xor 	rax, rax

createOutput:
	;create file with the given name
	mov 	rax, 85 					;85 only for creating
	mov 	rdi, [destinationFileIO]
	mov 	rsi, 666o
	mov 	rcx, 0
	syscall
	cmp 	rax, 0
	jl 		Error3
	mov 	[outputFileD], rax 			;save file discriptor

openOutput2:
	mov 	rax, 2	 					;open file
	mov 	rdi, [destinationFileIO] 	;address of the file name
	mov 	rsi, 0442h					;readbuffer into
	mov 	rdx, 2 						;open for read and write
	syscall		 						;poke kernal
	cmp 	rax, 0					
	jl 		Error3  


readInput:
	mov 	rax, 0						;read from file
	mov 	rdi, [inputFileD]			;file discriptor into rdx
	mov 	rsi, [oldBottomAddress]		;write to buffer 
	mov 	rdx, 0ffffh					;size of buffer
	syscall 	
	cmp 	rax, 0					
	jl 		Error3
	mov  	[bytecount], rax			;store total bytes read
	add 	r10, rax
;///////////////////////////////////////////////////////////////////////

call Encrypt

;//////////////////////////////////////////////////////////////////////////////////////////
 
WriteOutput:

	mov 	rax, 1
	mov 	rdi, [outputFileD]
	mov 	rsi, [oldBottomAddress]
	mov 	rdx, [bytecount]
	syscall
	cmp 	rax, 0
	jl 		Error4
	cmp 	rdx, 0ffffh
	jl 	Done
	jmp  readInput



Done:
	push bytereadPrompt
	push bytereadPrompt.len
	call PrintText

	
	push r10
	call Print64bitNumDecimal
	call Printendl

jmp Exit

Error1:
	push 	errorPrompt
	push 	errorPrompt.len
	call 	PrintText
	call 	Printendl
Error2:
	push 	errorPrompt
	push 	errorPrompt.len
	call 	PrintText
	call 	Printendl
Error3:
	push 	errorPrompt
	push 	errorPrompt.len
	call 	PrintText
	call 	Printendl
Error4:
	push 	errorPrompt
	push 	errorPrompt.len
	call 	PrintText
	call 	Printendl
;
;Setup the registers for exit and poke the kernel
;Exit: 
Exit:
	
	;close file
	mov 	rax, 3 					;close the file 
	mov 	rdi, [inputFileD] 		;file discriptor
	syscall							;poke kernal


	;close file
	mov 	rax, 3 				;close the file 
	mov 	rdi, [outputFileD] 	;file discriptor
	syscall					;poke kernal

	;restore our original memory area (delete the previously allocated memory)
	;need to clear the newBottomAddress
	mov rax, 0ch 					;sys_brk call
	mov rdi, [oldBottomAddress] 	;our original memory bottom
	syscall



	mov		rax, 60					;60 = system exit
	mov		rdi, 0					;0 = return code
	syscall							;Poke the kernel


Encrypt:
	xor 	rsi, rsi 									;clear rsi
	mov 	rsi, keyBuffer								;move userinput key into rsi register
	xor 	rdi, rdi 									;clear rdi
	mov 	rdi, [oldBottomAddress]						;move oldBottomAddress into rdi
	xor 	rax, rax 									;clear rax
	mov 	al, BYTE [keycount] 						;move into al (the 8bits of rax) the number of charaters inputed by user for key
	xor 	rbx, rbx 									;clear rbx
	xor 	rcx, rcx 									;clear rcx
	mov 	rcx, [bytecount]  							;move into rcx(counter) the number of bytes in the file.

	encryptloop:

		cmp rax, [keycount]								;compare the current iteration of rax to the number of chars for key and loop
		jl cont 										;if rax has not reached the number of chars in the key, continue loop
		xor rax, rax 									;clear rax
		mov rsi, keyBuffer

		cont: 	
		mov bl, [rdi] 									;move charater from Sbuffer into bl
		xor bl, [rsi] 									;xor value inside bl with value in key
		mov [rdi], bl 									;move xor-ed value in bl to encryptbuffer

		inc rsi
		inc rax 										;increase loop counter
		inc rdi
	loop encryptloop
	ret