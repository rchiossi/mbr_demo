;;; Lissajous Curves Demo for IO
;;; by p1ra
	
BITS 16
	
%define NPOINTS 	0x7FFF
%define SCALEX		0x50
%define SCALEY		0x50	
%define MAXRATIO	0xE

%define STEP		[ebp-4]	
%define RATIO		[ebp-4]	
%define RES		[ebp-4]
%define T		[ebp-8]	
%define RATE		[ebp-12]
%define SCALE		[ebp-16]

SECTION .text

init:
	mov ebp,esp
	sub esp,0x4
	
	;; set video mode to 320x200
	mov ax,0x13
	int 0x10

	;; set video address to es
	push 0xA000
	pop es

	push 0x7BFF
	pop ds
	;; set pallete ------

	;; set color index 0
	xor al,al
	mov dx,0x3c8
	out dx,al
	;; set color components
	inc dx
	mov al,0x00
	out dx,al 		;red
	mov al,0x00 		
	out dx,al		;green
	mov al, 0x00
	out dx,al		;blue

	;; set color index 1
	mov al,0x1
	mov dx,0x3c8
	out dx,al
	;; set color components
	inc dx
	mov al,0x00
	out dx,al 		;red
	mov al,0xF0 		
	out dx,al		;green
	mov al, 0x11
	out dx,al		;blue

	;; set color index 2
	mov al,0x2
	mov dx,0x3c8
	out dx,al
	;; set color components
	inc dx
	mov al,0x1f
	out dx,al 		;red
	mov al,0x1f 		
	out dx,al		;green
	mov al, 0x00
	out dx,al		;blue
	
	;; end set pallet -----

	mov STEP,word 0x2
	mov di,0x6
_draw:
	;; fill the background ------
	mov bx,0xfa00
_fill_loop:
	xor al,al
	mov byte [bx],al
	dec bx
	jnz _fill_loop
	;; end fill the background ---

	;; draw IO -----------
	mov ax,word 0x2 	;set color

	;; draw 'I'
	mov bx,0x140*0x1c+0x2d
	mov cx,0x2d*2
	mov dx,0x1c
	call p_draw_block

	mov bx,0x140*2*0x1c+0x2d + 0x2d-0x1c/2
	mov cx,0x1c
	mov dx,0x54
	call p_draw_block

	mov bx,0x140*5*0x1c+0x2d
	mov cx,0x2d*2
	mov dx,0x1c
	call p_draw_block

	;; draw 'O'

	mov bx,0x140*0x1c+0x2d*4
	mov cx,0x2d*2
	mov dx,0x1c
	call p_draw_block

	mov bx,0x140*2*0x1c+0x2d*4
	mov cx,0x1c
	mov dx,0x54
	call p_draw_block

	mov bx,0x140*2*0x1c+0x2d*5 + 0x2d-0x1c
	mov cx,0x1c
	mov dx,0x54
	call p_draw_block
	
	mov bx,0x140*5*0x1c+0x2d*4
	mov cx,0x2d*2
	mov dx,0x1c
	call p_draw_block

	;; draw the curve ----------
	mov ax,di
	call p_draw_lis

	;; update ratio -----------
	mov ax,STEP
	cmp di,MAXRATIO
	je _inv
	cmp di,word 0x4
	jz _inv
	jmp _update_ratio
_inv:
	neg ax
	mov STEP,ax
_update_ratio:	
	add di,ax

	;; swap buffer
	push di
	mov cx,320*200/2
	xor si,si
	xor di,di
	rep movsw
	pop di
	
	;; wait 0.5s --------
	mov cx,word 0x3
	mov dx,word 0xA120
	mov ah,0x86
	int 0x15

	jmp _draw
	
p_draw_lis:
	push ebp
	mov ebp,esp
	sub esp,0x4
	
	mov RATIO,ax
	
	mov cx,word NPOINTS
_loop_lis:
	mov ax,cx
	mov bx,0x1
	mov dx,SCALEX
	call p_calc_pos
	mov bx,ax		;bx = x

	push bx			;save x value
	
	mov ax,cx
	mov bx,RATIO
	mov dx,SCALEY
	call p_calc_pos

	pop bx 			;restore x value

	mov dx,0xc8
	sub dx,ax
	mov ax,dx
	
	add ax,0x64 		;align y to center

	mov dx,0x140
	mul dx
	add bx,ax

	add bx,0x5A
	
	mov al,0x1
	mov byte [bx],al
	
	dec cx
	jnz _loop_lis

	add esp,0x4
	pop ebp
	ret
	
;;; calculate xy for the lissajous curve
;;; xy = scale*sin(t*rate*2pi/npoints)
p_calc_pos:
	push ebp
	mov ebp,esp	
	sub esp,0x20

	mov T,ax
	mov RATE,bx
	mov SCALE,dx
	
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
	
	fild word SCALE		;push scale
	fmulp st1,st0		;scale*sin(g)
	
	fistp word RES	;pop RES
	mov ax,RES
	
	add esp, 0x20
	pop ebp
	ret	 

p_draw_h_line:
	mov byte [bx],al
	inc bx	
	dec cx
	jnz p_draw_h_line	
	ret

p_draw_v_line:
	mov byte [bx],al
	add bx,0x140
	dec cx
	jnz p_draw_v_line
	ret

%if 0
p_draw_block:
	push cx
	push bx
	call p_draw_h_line
	pop bx
	pop cx
	add bx,0x140
	dec dx
	jnz p_draw_block
	ret
%else
p_draw_block:
	push cx
	push bx
	call p_draw_h_line
	pop bx
	pop cx
	add bx,0x140
	dec dx
	jnz p_draw_block
	ret
%endif
	
times 446 - ($ - $$) db 'U' 	;padding
times 64 db 'x' 		;partition table
db 0x55,0xaa
