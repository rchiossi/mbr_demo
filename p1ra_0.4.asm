BITS 16
	
%define NPOINTS 	0x7FFF
%define SCALE		0x50

%define RES		[ebp-4]
%define T		[ebp-8]	
%define RATE		[ebp-12]

SECTION .text

init:
	;; set video mode to 320x200
	mov ax,0x13
	int 0x10

	;; set video address to ds
	push 0xA000
	pop ds

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
	mov byte [bx],al
	dec bx
	jnz _fill_loop
	;; end fill the background ---

	;; draw the curve ----------
	mov cx,word NPOINTS
_loop_lis:
	mov ax,cx
	mov bx,0x1
	call p_calc_pos
	mov bx,ax		;bx = x

	push bx			;save x value
	
	mov ax,cx
	mov bx,0x8
	call p_calc_pos

	pop bx 			;restore x value

	%if 1
	mov dx,0xc8
	sub dx,ax
	mov ax,dx
	%endif
	
	add ax,0x64 		;align y to center

	mov dx,0x140
	mul dx
	add bx,ax

	add bx,0x5A
	
	mov al,0x1
	mov byte [bx],al
	
	dec cx
	jnz _loop_lis
	
;;; stop
_wait_forever:
	jmp _wait_forever	

;;; calculate X for the lissajous curve
;;; x = scale*sin(t*rate*2pi/npoints)
p_calc_pos:
	push ebp
	mov ebp,esp	
	sub esp,0x16

	mov T,ax
	mov RATE,bx
	
	fldpi			;push pi
	
	mov [esp],word 0x2
	fild word [esp]		;push 2

	fmulp st1,st0		;2*pi

	fild word RATE		;push rate
	fild word T		;push t
	fmulp st1,st0 		;a*t
	
	mov [esp], word NPOINTS 
	fild word [esp]		;push npoints	

	fdivp st1,st0		;(a*t)/npoints

	fmulp st1,st0		;(2*pi)*(a*t)/npoints = g
	
	fsin			;sin(g)
	
	mov [esp], word SCALE
	fild word [esp]		;push scale
	fmulp st1,st0		;scale*sin(g)
	
	fistp word RES	;pop RES
	mov ax,RES
	
	add esp, 0x16
	pop ebp
	ret	 

times 446 - ($ - $$) db 'U' 	;padding
times 64 db 'x' 		;partition table
db 0x55,0xaa
