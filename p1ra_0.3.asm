BITS 16
	
%define NPOINTS 	0x80
%define SCALE		0x40

;%define RES	WORD [ebp-24]
;%define DF	WORD [ebp-24]

SECTION .data
DF:	db 0
RES:	db 0

SECTION .text

init:
	;; set video mode to 320x200
	mov ax,0x13
	int 0x10

	;; set video address to ds
	push 0xA000
	pop es

	;; set pallete ------

	;; set color index 0
	xor al,al
	mov dx,0x3c8
	out dx,al
	;; set color components
	inc dx
	mov al,0xaa
	out dx,al 		;red
	mov al,0x88 		
	out dx,al		;green
	mov al, 0x11
	out dx,al		;blue

	;; set color index 1
	mov al,0x1
	mov dx,0x3c8
	out dx,al
	;; set color components
	inc dx
	mov al,0x00
	out dx,al 		;red
	mov al,0x88 		
	out dx,al		;green
	mov al, 0x11
	out dx,al		;blue

	;; end set pallet -----

	;; fill the background ------
	mov bx,0xfa00
_fill_loop:
	xor al,al
	mov byte [es:bx],al
	dec bx
	jnz _fill_loop
	;; end fill the background ---
	
	;; draw the curve ----------
	mov dx,0x1
	mov [DF],word dx

	mov cx,0x140
_loop_lis:
	call p_calc_sin

	mov ax,[RES]		;ax = y
	mov bx,cx		;bx = x
	
	add ax,0x64 		;align to center

	mov dx,0x140
	mul dx
	add bx,ax
	
	mov al,0x1
	mov byte [es:bx],al
	
	dec cx
	jnz _loop_lis
	
;;; stop
_wait_forever:
	jmp _wait_forever	
	
;;; calculate the sin
p_calc_sin:
	sub esp,0x4		;stack lifting
	
	fldpi			;push pi to fp stack

	mov [esp],word 0x2
	fild word [esp]		;push 2 to fp stack

	fmulp st1,st0		;pi*2
	
	fild word [DF]		;push df to fp stack

	mov [esp], word NPOINTS
	fild word [esp]		;push NPOINTS to fp stack
	
	fdivp st1,st0		;df/NPOINTS

	fmulp st1,st0		;(pi*2)*(df/NPOINTS)

	mov dx,[DF]		;update div factor (df)
	inc dx
	mov [DF],dx

	fsin			;sin(pi*2/a)
	
	mov word [esp],SCALE
	fild word [esp]
	fmulp st1, st0		;expand the result for plotting
	
	fistp word [RES]	;pop x from fp stack

	add esp,0x4
	ret
	
times 446 - ($ - $$) db 'U' 	;padding
times 64 db 'x' 		;partition table
db 0x55,0xaa
