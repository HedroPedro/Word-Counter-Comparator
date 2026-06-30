bits 64
%define STDERR_FILENO 0x2
%define O_RDONLY 0x0
%define PROT_READ 0x1
%define ENDL 0xA, 0x0
%assign MMAP_SIZE 4*1024

section .data
	a1: dq new_word
	a2: dq inside_word
	a3: dq between_words
	args_err_str: db 'Try calling ./main <file>', ENDL
	open_err: db 'NOT ABLE TO OPEN FILE ', 0
	mmap_err: db 'MMAP ERROR', ENDL

section .text
global _start

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
	mov rax, 0xA
	lea rsi, [rsp-1]
	push 0
	sub rsp, 12
	.loop:
		

	call print_str
	add rsp, 20
	ret

; This function represents the a0 state
; rdi - ptr
; rax - word counter
; rdx - character counter
automata:
	push rcx
	xor rax, rax
	xor rdx, rdx
	mov sil, [rdi]
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
		jmp [rcx]
end_automata:
	pop rcx
	ret

new_word:
	inc rdi
	inc rax
	inc rdx
	mov sil, [rdi]
	test sil, sil
	jz end_automata
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
	jmp [rcx]

inside_word:
	inc rdi
	inc rdx
	mov sil, [rdi]
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
	cmovb rcx, qword[a3]
	cmp sil, 'z'
	cmovbe rcx, qword[a1]

	jmp [rdx]

between_words:
	inc rdi
	inc rdx
  mov sil, [rdi]
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
	cmovb rcx, qword[a3]
	cmp sil, 'z'
	cmovbe rcx, qword[a1]

	jmp [rcx]

; rdi - Exit code
exit:
	mov rax, 60
	syscall

_start:
	cmp byte[rsp], 2
	jae short .have_arg
	mov rsi, args_err_str
	mov rdi, STDERR_FILENO
	call print_str
	mov rdi, 1
	call exit
	.have_arg:
	xor rdx, rdx
	mov rdi, [rsp+16]
	mov rsi, O_RDONLY
	syscall
	cmp rax, -1
	jne .mmap:
	.file_error:
	mov rsi, open_err
	mov rdi, STDERR_FILENO
	call print_str
	.mmap:
	.end:
	xor rdi, rdi
	call exit
