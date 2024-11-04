
;  Description: function to read characters from a file using a buffer 
; and to also write characters to a file

;  Functions Template

; ***********************************************************************
;  Data declarations
;	Note, the error message strings should NOT be changed.
;	All other variables may changed or ignored...

section	.data

; -----
;  Define standard constants.
; test

TRUE		equ	1
FALSE		equ	0

SUCCESS		equ	0			; successful operation
NOSUCCESS	equ	1			; unsuccessful operation

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

SYS_read	equ	0			; system call code for read
SYS_write	equ	1			; system call code for write
SYS_open	equ	2			; system call code for file open
SYS_close	equ	3			; system call code for file close
SYS_lseek	equ	8			; system call code for file repositioning
SYS_fork	equ	57			; system call code for fork
SYS_exit	equ	60			; system call code for terminate
SYS_creat	equ	85			; system call code for file open/create
SYS_time	equ	201			; system call code for get time

LF		equ	10
SPACE		equ	" "
NULL		equ	0
ESC		equ	27

O_CREAT		equ	0x40
O_TRUNC		equ	0x200
O_APPEND	equ	0x400

O_RDONLY	equ	000000q			; file permission - read only
O_WRONLY	equ	000001q			; file permission - write only
O_RDWR		equ	000002q			; file permission - read and write

S_IRUSR		equ	00400q
S_IWUSR		equ	00200q
S_IXUSR		equ	00100q

; -----
;  Define program specific constants.

BUFF_SIZE	equ	800000			; buffer size

; -----
;  Variables for getOptions() function.

eof		db	FALSE

usageMsg	db	"Usage: blowfish <-en|-de> -if <inputFile> "
		db	"-of <outputFile>", LF, NULL
errIncomplete	db	"Error, command line arguments incomplete."
		db	LF, NULL
errExtra	db	"Error, too many command line arguments."
		db	LF, NULL
errFlag		db	"Error, encryption/decryption flag not "
		db	"valid.", LF, NULL
errReadSpec	db	"Error, invalid read file specifier.", LF, NULL
errWriteSpec	db	"Error, invalid write file specifier.", LF, NULL
errReadFile	db	"Error, opening input file.", LF, NULL
errWriteFile	db	"Error, opening output file.", LF, NULL

; -----
;  Variables for getX() function.

buffMax		dq	BUFF_SIZE
curr		dq	BUFF_SIZE
wasEOF		db	FALSE
placedLastBlock db FALSE

errRead		db	"Error, reading from file.", LF,
		db	"Program terminated.", LF, NULL

; -----
;  Variables for writeX() function.

errWrite	db	"Error, writting to file.", LF,
		db	"Program terminated.", LF, NULL

; -----
;  Variables for readKey() function.

chr		db	0

keyPrompt	db	"Enter Key (16-56 characters): ", NULL
keyError	db	"Error, invalid key size.  Key must be between 16 and "
		db	"56 characters long.", LF, NULL

; ------------------------------------------------------------------------
;  Unitialized data

section	.bss

buffer		resb	BUFF_SIZE


; ############################################################################

section	.text

; ***************************************************************
;  Routine to get arguments (encryption flag, input file
;	name, and output file name) from the command line.
;	Verify files by atemptting to open the files (to make
;	sure they are valid and available).

;  Command Line format:
;	./blowfish <-en|-de> -if <inputFileName> -of <outputFileName>

; -----
;  Arguments:
;	argc (value) , rdi 
;	address of argv table , rsi 
;	address of encryption/decryption flag (byte) , rdx 
;	address of read file descriptor (qword) , rcx 
;	address of write file descriptor (qword)r8
;  Returns:
;	TRUE or FALSE

global getOptions
getOptions:

; pushing perserved registers
push rbp
push r12
push r13 
push r14 

; now need to place arguments into perserved registers because sys calls
mov r12, rsi ; r12 will have argv address 
mov r13, rcx ; r13 will have the read file decsriptor passed 
mov r14, r8 ; r14 will have write file descriptor 

; checking argument count 
; if no arguments are placed 
cmp rdi, 1
 jbe errorNoArguments
; if not enough arguments are placed 
cmp rdi, 6  ; 6 arguments are needed including the executable name 
jb errorNotEnoughArguments
; if too many arguments are placed 
cmp rdi, 6 
ja errorTooManyArguments

; checking if encryption/decryption flag is valid 
; getting access to the address of encryption/decryption string 
mov r9, qword[rsi + 8]
; checking the actual encryption/decryption string 
cmp byte[r9], NULL
je errorFlag
cmp byte[r9], 45 ; '-' is 45 ascii 
jne errorFlag

; checking if the rest of the string is 'en'
cmp byte[r9+1], NULL ; 
je errorFlag
cmp byte[r9+1], 101 ; 'e' is 101 ascii 
jne decryptionFlag
cmp byte[r9+2], NULL ; 
je errorFlag
cmp byte[r9+2], 110 ; 'n' is 110 ascii 
jne decryptionFlag

; string is '-en' so skip checking for decryption flag
jmp encryptionFlag

decryptionFlag: 
; checking if the rest of string is 'de'
cmp byte[r9+1], NULL ; 
je errorFlag
cmp byte[r9+1], 100 ; 'd' is 100 ascii 
jne errorFlag
cmp byte[r9+2], NULL ; 
je errorFlag
cmp byte[r9+2], 101 ; 'e' is 101 ascii 
jne errorFlag

encryptionFlag: 
; setting flag to true at the start 
mov byte[rdx], TRUE

; now checking if encyption flag should be true or false 
cmp byte[r9+1], 101 ; 'e' is 101 ascii 
je shouldEncryption ; first letter is e so should encrypt

shouldDecryption:
mov byte[rdx], FALSE

shouldEncryption:
; already set to true at start 


; will be checking read file specfier 
; getting access to the address of the read file specfier string 
mov r9, qword[rsi + 16]
; checking the actual read file specifer string 
cmp byte[r9], NULL ; 
je errorReadSpecifier
cmp byte[r9], 45 ; '-' is 45 ascii 
jne errorReadSpecifier
cmp byte[r9+1], NULL ; 
je errorReadSpecifier
cmp byte[r9+1], 105 ; 'i' is 105 ascii 
jne errorReadSpecifier
cmp byte[r9+2], NULL ; 
je errorReadSpecifier
cmp byte[r9+2], 102 ; 'f' is 102 ascii 
jne errorReadSpecifier

; will be checking write file specifier 
; getting access to the address of the write file specfier string 
mov r9, qword[rsi + 32]
; checking the actual read file specifer string 
cmp byte[r9], NULL ; 
je errorWriteSpecifier
cmp byte[r9], 45 ; '-' is 45 ascii 
jne errorWriteSpecifier
cmp byte[r9+1], NULL ; 
je errorWriteSpecifier
cmp byte[r9+1], 111 ; 'o' is 111 ascii 
jne errorWriteSpecifier
cmp byte[r9+2], NULL ; 
je errorWriteSpecifier
cmp byte[r9+2], 102 ; 'f' is 102 ascii 
jne errorWriteSpecifier

; checking if we can read the file passed in the command line 
; opening the read file 
openReadFile:
; getting the address of the read file name string 
mov r9, qword[r12 + 24]

	mov	rax, SYS_open			; system call for file open
	mov	rdi, r9			; ebx = file name string (NULL terminated)
	mov	rsi, O_RDONLY			; read only access
	syscall					; call the kernel

	cmp	rax, 0				; check for successful open?
	jl	errorReadFile

	mov	qword [r13], rax	; if opened, save read file descriptor

; checking if we can write to the file name passed in command line
; opening the write file 
openWriteFile:
; getting the address of the write file name string 
mov r9, qword[r12 + 40]

	mov	rax, SYS_creat			; system call for file open/create
	mov	rdi,  r9			; ebx = file name string (NULL terminated)
	mov	rsi, S_IRUSR | S_IWUSR		; allow read/write access 
	syscall					; call the kernel

	cmp	rax, 0				; check for success
	jl	errorWriteFile

	mov	qword [r14], rax	; if opened, save descriptor

; if no errors triggered return true and skip returning false 
mov rax, TRUE
jmp returnTrue

; error messages 
errorNoArguments:
mov rdi, usageMsg
call printString
jmp returnFalse

errorNotEnoughArguments:
mov rdi, errIncomplete
call printString
jmp returnFalse

errorTooManyArguments:
mov rdi, errExtra
call printString
jmp returnFalse

errorFlag:
mov rdi, errFlag
call printString
jmp returnFalse

errorReadSpecifier:
mov rdi, errReadSpec
call printString
jmp returnFalse

errorWriteSpecifier:
mov rdi, errWriteSpec
call printString
jmp returnFalse

errorReadFile:
mov rdi, errReadFile
call printString
jmp returnFalse

errorWriteFile:
mov rdi, errWriteFile
call printString
jmp returnFalse

; jump to this line after outputting an error message 
returnFalse:
mov rax, FALSE


returnTrue:

; popping back perserved registers
pop r14
pop r13
pop r12
pop rbp 

ret 


; ***************************************************************
;  Return the 64-bits or 8 characters from read buffer.
;	This routine performs all buffer management.

; -----
;   Arguments:
;	value of read file descriptor
;	address of block array
;	address of block size
;  Returns:
;	TRUE or FALSE

;     NOTE's:
;	- returns TRUE when block array has been filled
;	- if < 8 characters in buffer, NULL fill with NULLS
;		and set block size accordingly
;	- returns FALSE only when asked for 8 characters
;		but there are NO more at all (which occurs
;		only when ALL previous characters have already
;		been returned).

;  The read buffer itself and some misc. variables are used
;  ONLY by this routine and as such are not passed.

global getBlock
getBlock: 
; pushing perserved registers 
push rbp 
push rbx 
push r12
push r13 
push r14 
push r15 

; placing arguments into persereved registers
 mov r12, rdi ; r12 will have value of read file descriptor 
	mov r13, rsi ; r13 will have the address of the block array
	mov r14, rdx ; rdx will have the address of the block size 

	; checking if placed last block 
mov r10, 0
mov r10b, byte[placedLastBlock]
cmp r10, TRUE
je getReturnFalse



; will be counter for loop 
mov r15, 8 
mov rbx, 0 ; will be index counter for block array 

; call get byte 8 times or until eof is set and end of buffer is reached
getByteLoop:

; getting byte from get byte function 
; byte will be returned in rax ; al part 
; passing arguments 
mov rdi, r12 ; passign value of read file descriptor
mov rax, 0 
call getByte

; will check if byte returned is -1 if it is there was a read error 
cmp rax, -1 
je errorReadMessage

; will check if eof reached and buffer is empty and that's when rax is -2
; this means the last bytes are in the buffer 
cmp rax, -2
je returnLastBlock

; placing byte into block array 
mov byte[r13 + rbx], al ; byte part of rax is al 

; incrementing index for array 
inc rbx 

; decrementing loop counter and checking if loop should be terminated
dec r15 
cmp r15, 0 
jne getByteLoop
; exit getByteLoop 
endGetByteLoop:

; if no problems up to this point and got the block return true 
mov rax, TRUE
; this means block size should be 8 
mov r10, 8 ; 8 in r10 
; placing 8 into block size variable 
mov dword[r14], r10d
; placintg null at the end 
mov byte[r13+rbx], NULL
jmp getReturnEnd

errorReadMessage:
mov rdi, errRead
call printString
jmp getReturnFalse

getReturnFalse:
mov rax, FALSE
jmp getReturnEnd

returnLastBlock: 
; returning true 
mov rax, TRUE
; setting placed last block bool variable 
mov r10, TRUE
mov byte[placedLastBlock], r10b

; this means the block size will depend on number of chars in block already
; this also means need to fill the rest of the block array with nulls 
; first chekcing if rbx is 0 
cmp rbx, 0 
je getReturnEnd; exit fucntion if rbx is 0 meaning a read error 

; setting block size
mov r10, rbx
mov dword[r14], r10d 

; now lets place the reaming chars in the block to null 
mov rcx, 8
sub rcx, rbx 
; use r10 as index counter 
mov r10, rbx ; 
; loop to place null chars in rest of the block array 
placeNullsLoop:
; placing null into block array 
mov byte[r13 +r10], NULL

; incrementing r10 our index counter 
inc r10

loop placeNullsLoop
; placing null at the end as well 
mov byte[r13+r10], NULL

getReturnEnd:
; popping back persereved registers
pop r15 
pop r14 
pop r13 
pop r12 
pop rbx 
pop rbp

ret

; ***************************************************************
; getByte function 
; -----
;   Arguments:
;	rdi - value of read file descriptor
;  Returns in rax:
;	a byte from the current buffer 
; will return -1 for the byte if there is a read error 
; will return -2 if the eof and buffer is empty meaning reading is done 
global getByte
getByte: 

; first check if buffer is empty that is when curr is equal to buffMax 
; also check if eof is true if it is return -2 meaning stop getting blocks 

; if it is just empty get a new buffer by reading 800,000 bytes from the file
; store the characters into the buffer and reset curr to 0 
; if there is a read error return -1 

; check if number of characters read 800k is less than the actual numbers read
; if it is set eof flag and set buffmax to actual bytes read could be <= 800k

; if buffer not empty get a byte from the buffer 
; update curr position and return the byte that ws got 

; pushing perserved registers 
push rbp 
push r12 
; placing 1st argument in a perserved register 
mov r12, rdi ; placing value of read file descriptor in r12 

; clear rax register
mov rax, 0

; checking if buffer is empty curr == buffmax and if eof is true 
mov r10, qword[curr]
cmp r10, qword[buffMax]
je endOfFileReached
jmp isBufferEmpty
; checking if eof is true 
endOfFileReached:
mov r10, 0
mov r10b, byte[wasEOF]
cmp r10, TRUE
je stopReadingBytes

; just checking if buffer is empty 
isBufferEmpty:
mov r10, qword[curr]
cmp r10, qword[buffMax]
jne getByteFromBuffer

; to read a file and get bytes and store it into the buffer 
readFileGetBuffer:
mov	rax, SYS_read
	mov	rdi, r12 ; r12 has the read file descriptor
	mov	rsi, buffer
	mov	rdx, BUFF_SIZE
	syscall

; checking if there was a read error 
	cmp	rax, 0
	jl	errorReadingFile

	; setting buffmax which will be the number of chars actually read
	mov qword[buffMax], rax
	; resetting curr 
	mov r10, 0 
	mov qword[curr], r10

	; will be checking if eof was reached rax < BUFF_SIZE
	cmp rax, BUFF_SIZE
	jl setEndOfFile
	jmp endOfFileNotReached

	setEndOfFile:
	mov r10, TRUE
	mov byte[wasEOF], r10b

	endOfFileNotReached:

; get byte from buffer and store it in rax 
getByteFromBuffer:
; getting curr and placing it in r10 
mov r10, qword[curr]
; getting byte and placing it in rax 
mov rax, 0 
mov al, byte[buffer + r10]
; incrementing curr
inc r10 
mov qword[curr], r10

; if got byte normally and no errors and do not need to stop reading bytes
jmp returnByte ; skip to end and avoid error returns

; to return -1 becuase there was a read error
errorReadingFile:
mov rax, -1 
jmp returnByte

; to return -2 because eof and end buffer was reached 
stopReadingBytes: 
mov rax, -2

; to return byte normally 
returnByte:

; popping persereved registers back 
pop r12 
pop rbp 


ret

; ***************************************************************
;  Write block array, up to 64-bits (8 characters) to output file.
;	No requirement to buffer here.
;	NOTE:	this routine returns FALSE only if there is
;		an error on write (which would not normally occur).

; -----
;  Arguments are:
;	value of write file descriptor
;	address of block array
;	value of block size
;  Returns:
;	TRUE or FALSE

global writeBlock
writeBlock:
; pushing perserved registers 
push rbp
push r12
push r13
push r14

; placing arguments in perserved registers
mov r12, rdi ; r12 has the value of the write file descriptor
mov r13, rsi ; r13 has the address of the block array 
mov r14, rdx ; r14 has the value of the block size


; writing block to file 
mov	rax, SYS_write
	mov	rdi, r12
	mov	rsi, r13
	mov	rdx, r14
	syscall

; if there is a write error (which normally does not happen)
	cmp	rax, 0
	jl	writingBlockError

; if no error messages jump to return true 
mov rax, TRUE
jmp writeReturnTrue

; error message wrting file error 
writingBlockError:
mov rdi, errWrite
call printString
jmp writeReturnFalse

writeReturnFalse: 
mov rax, FALSE

writeReturnTrue: 

; poping back perserved registers
pop r14
pop r13
pop r12
pop rbp 

ret

; ***************************************************************
;  Get a encryption/decryption key from user.
;	Key must be between MIN and MAX characters long.

;  NOTE:  must ensure there is no buffer overflow
;	 if the user enters >MAX characters

; -----
;  Arguments:
;	address of the key buffer
;	value of key MIN length
;	value of key MAX length
;  Returns:
;	TRUE or FALSE
global readKey
readKey:
; saving persereved registers 
push rbp 
push r12
push r13
push r14 
push r15 

; placing arguments in persereved registers 
mov r12, rdi ; will have adress of key buffer 
mov r13, rsi ; will have min
mov r14, rdx ; will have max 

; print string to tell user to input key
mov rdi, keyPrompt
call printString

; getting key string 
; -----
; Read characters from user (one at a time)
; r12 has the adress of the key buffer 
mov r15, 0 ; char count
readCharacters:
mov rax, SYS_read ; system code for read
mov rdi, STDIN ; standard in
lea rsi, byte [chr] ; address of chr
mov rdx, 1 ; count (how many to read)
syscall ; do syscall
mov al, byte [chr] ; get character just read
cmp al, LF ; if linefeed, input done
je readDone
inc r15 ; count++
cmp r15, r14 ; if # chars ≥ STRLEN
jae readCharacters ; stop placing in buffer
mov byte [r12], al ; inLine[i] = chr
inc r12 ; update tmpStr addr
jmp readCharacters
readDone:
mov byte [r12], NULL ; add NULL terminal 

; checking if key length is less than min 
cmp r15, r13 
jb keyWasInvalid
; checking if key length is greater than max 
cmp r15, r14 
ja keyWasInvalid

; no error for the keys so return true and skip setting setting key to false
mov rax, TRUE
jmp keyIsValid

; print error message 
keyWasInvalid:
mov rdi, keyError
call printString
mov rax, FALSE

keyIsValid: 

; popping at the end 
pop r15 
pop r14
pop r13
pop r12
pop rbp 
ret 

; ***************************************************************
;  Generic function to display a string to the screen.
;  String must be NULL terminated.

;  Algorithm:
;	Count characters in string (excluding NULL)
;	Use syscall to output characters

; -----
;  HLL Call:
;	printString(stringAddr);

;  Arguments:
;	1) address, string
;  Returns:
;	nothing

global	printString
printString:

; -----
;  Count characters to write.

	mov	rdx, 0
strCountLoop:
	cmp	byte [rdi+rdx], NULL
	je	strCountLoopDone
	inc	rdx
	jmp	strCountLoop
strCountLoopDone:
	cmp	rdx, 0
	je	printStringDone

; -----
;  Call OS to output string.

	mov	rax, SYS_write			; system code for write()
	mov	rsi, rdi			; address of char to write
	mov	rdi, STDOUT			; file descriptor for std in
						; rdx=count to write, set above
	syscall					; system call

; -----
;  String printed, return to calling routine.

printStringDone:
	ret

; ***************************************************************

