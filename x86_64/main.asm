bits 64
%define STDOUT_FILENO 0x1
%define STDERR_FILENO 0x2
%define O_RDONLY 0x0
%define PROT_READ 0x1
%define MAP_SHARED 0x1
%define ENDL 0xA, 0x0
%assign MMAP_SIZE 4*1024

%macro close_fp 1
	%if %1 != rdi
		mov rdi, %1
	%endif
	mov rax, 3
	syscall
%endmacro

%macro unmap 1
	%if %1 != rdi
		mov rdi, %1
	%endif
	mov rax, 11
	mov rsi, MMAP_SIZE
	syscall
%endmacro

section .data
	a1: dq new_word
	a2: dq inside_word
	a3: dq between_words
	args_err: db 'Try calling ./main <file>', ENDL
	open_err: db 'NOT ABLE TO OPEN FILE: ', 0
	mmap_err: db 'MMAP ERROR', ENDL
	file_info: db 'File contents: ', 0
	words_info: db 'Amount of words: ', 0
	chars_info: db 'Amount of characters: ', 0

section .text
global _start

; rdi - file desc
print_newline:
	push 0xA
	mov rsi, rsp
	mov rdx, 1
	mov rax, 1
	syscall
	add rsp, 8
	ret

; rdi - file desc
; rsi - file ptr
print_str:
	mov rax, 1
	xor rdx, rdx
	.loop:
		cmp byte[rsi+rdx], 0
		jz .end
		inc rdx
		jmp .loop
	.end:
	syscall
	ret

; rdi - file desc
; rsi - number
print_uint:
	push rcx
	mov rax, rsi
	lea rsi, [rsp-1]
	push 0
	sub rsp, 16
	mov rcx, 0xA
	.loop:
		xor rdx, rdx
		div rcx
		or dl, 48
		dec rsi
		mov [rsi], dl
		test rax, rax
		jnz .loop

	call print_str
	add rsp, 24
	pop rcx
	ret

; This function represents the a0 state
; rdi - ptr
; rax - word counter
; rdx - character counter
automata:
	push rcx
	xor rax, rax
	xor rdx, rdx
	movzx esi, byte[rdi]
	test sil, sil
	jz end_automata
	.body:
		mov rcx, between_words
		cmp sil, '0'
		cmovb rcx, qword[a3]
		cmp sil, '9'
		cmovbe rcx, qword[a1]
		cmp sil, 'A'
		cmovb rcx, qword[a3]
		cmp sil, 'Z'
		cmovbe rcx, qword[a1]
		cmp sil, 'a'
		cmovbe rcx, qword[a3]
		cmp sil, 'z'
		cmovbe rcx, qword[a1]

		jmp rcx
end_automata:
	pop rcx
	ret

new_word:
	inc rdi
	inc rax
	movzx esi, byte[rdi]
	test sil, sil
	jz end_automata
	inc rdx
	.body:
	mov rcx, between_words
	cmp sil, '0'
	cmovb rcx, qword[a3]
	cmp sil, '9'
	cmovbe rcx, qword[a2]
	cmp sil, 'A'
	cmovb rcx, qword[a3]
	cmp sil, 'Z'
	cmovbe rcx, qword[a2]
	cmp sil, 'a'
	cmovb rcx, qword[a3]
	cmp sil, 'z'
	cmovbe rcx, qword[a2]
	
	jmp rcx

inside_word:
	inc rdi
	movzx esi, byte[rdi]
	test sil, sil
	jz end_automata
	inc rdx
	.body:
	mov rcx, between_words
	cmp sil, '0'
	cmovb rcx, qword[a3]
	cmp sil, '9'
	cmovbe rcx, qword[a2]
	cmp sil, 'A'
	cmovb rcx, qword[a3]
	cmp sil, 'Z'
	cmovbe rcx, qword[a2]
	cmp sil, 'a'
	cmovb rcx, qword[a3]
	cmp sil, 'z'
	cmovbe rcx, qword[a2]
	cmp sil, ' '
	cmove rcx, qword[a3]
	cmp sil, 13
	cmove rcx, qword[a3]
	cmp sil, 9
	cmove rcx, qword[a3]

	jmp rcx

between_words:
	inc rdi
	movzx esi, byte[rdi]
	test sil, sil
	jz end_automata
	inc rdx
	.body:
	mov rcx, between_words
	cmp sil, '0'
	cmovb rcx, qword[a3]
	cmp sil, '9'
	cmovbe rcx, qword[a1]
	cmp sil, 'A'
	cmovb rcx, qword[a3]
	cmp sil, 'Z'
	cmovbe rcx, qword[a1]
	cmp sil, 'a'
	cmovb rcx, qword[a3]
	cmp sil, 'z'
	cmovbe rcx, qword[a1]

	jmp rcx

; rdi - Exit code
exit:
	mov rax, 60
	syscall

_start:
	cmp byte[rsp], 2
	jae short .have_arg
	mov rsi, args_err
	mov rdi, STDERR_FILENO
	call print_str
	mov rdi, 1
	call exit
	.have_arg:
	xor rdx, rdx
	mov rdi, [rsp+16]
	mov rsi, O_RDONLY
	mov rax, 2
	syscall
	test rax, rax
	jns .mmap
	.file_error:
	mov rsi, open_err
	mov rdi, STDERR_FILENO
	call print_str
	mov rsi, [rsp+16]
	mov rdi, STDERR_FILENO
	call print_str
	mov rdi, STDERR_FILENO
	call print_newline
	add rsp, 8
	mov rdi, 1
	call exit
	.mmap:
	push rax
	xor rdi, rdi
	mov rsi, MMAP_SIZE
	xor r9, r9
	mov rdx, PROT_READ
	mov r8, [rsp]
  mov r10, MAP_SHARED
	mov rax, 9
	syscall
	test rax, rax
	jns .call_automata
	.mmap_err:
	mov rsi, mmap_err
	mov rdi, STDERR_FILENO
	call print_str
	pop rdi
	close_fp rdi
	mov rdi, STDOUT_FILENO
	call exit
	.call_automata:
	push rax
	mov rdi, rax
	call automata
	.print_info:
	push rdx
	push rax
	
	mov rdi, STDOUT_FILENO
	mov rsi, file_info
	call print_str
	
	mov rdi, STDOUT_FILENO
	mov rsi, [rsp+16]
	call print_str

	mov rdi, STDOUT_FILENO
	mov rsi, words_info
	call print_str

	mov rdi, STDOUT_FILENO
	pop rsi
	call print_uint
	call print_newline
	
	mov rdi, STDOUT_FILENO
	mov rsi, chars_info
	call print_str

	mov rdi, STDOUT_FILENO
	pop rsi
	call print_uint
	call print_newline
	
	.end:
	pop rdi
	unmap rdi
	pop rdi
	close_fp rdi
	xor rdi, rdi
	call exit
