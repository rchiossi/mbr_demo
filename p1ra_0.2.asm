BITS 16
	
%define NPOINTS 	0x80
%define SCALE		0x40
	
init:
	;; setup local variables
	mov esp,ebp
	xor eax,eax
	push eax
	;sub esp,0xc		

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

	;; fill the background
	mov bx,0xfa00
_fill_loop:
	xor al,al
	mov byte [bx],al
	dec bx
	jnz _fill_loop

	;; overwrite the image
	xor dx,dx 		
	inc dx			;initialize div factor (df)
	
	mov cx,0x140 		;for every x point do:
_sin_loop:
	fldpi			;push pi to fp stack

	mov [esp],word 0x2
	fild word [esp]		;push 2 to fp stack

	fmulp st1,st0		;pi*2
	
	push dx
	fild word [esp]		;push df to fp stack

	mov [esp], word NPOINTS
	fild word [esp]		;push NPOINTS to fp stack
	
	fdivp st1,st0		;df/NPOINTS

	fmulp st1,st0		;(pi*2)*(df/NPOINTS)

	inc dx			;update div factor (df)

	fsin			;sin(pi*2/a)
	
	mov word [esp],SCALE
	fild word [esp]
	fmulp st1, st0		;expand the result for plotting
	
	fistp word [esp]	;pop x from fp stack
	mov ax, word [esp]

	;; calculate point offset
	add ax,0x64		; align to the center
	mov bx, 0x140
	push dx			;save dx
	mul bx
	pop dx			;restore dx
	add ax,cx

	;; write to the screen
	mov bx,ax
	mov al,0x1
	mov byte [bx],al

	dec cx
	jnz _sin_loop

;;; stop
_wait_forever:
	jmp _wait_forever	

times 446 - ($ - $$) db 'U' 	;padding
times 64 db 'x' 		;partition table
db 0x55,0xaa
