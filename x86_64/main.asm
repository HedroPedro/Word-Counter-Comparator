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
	open_err: db 'Not able to open file ', 0
	mmap_err: db 'Not able call mmap', ENDL

section .text
global _start

; rdi - file desc
; rsi - file ptr
print_str:
	xor rax, rax
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


inside_word:

between_words:

_start:
	cmp byte[rsp], 2
	jb short .have_arg

	.have_arg:
	mov rax, 60
	xor rdi, rdi
	syscall
