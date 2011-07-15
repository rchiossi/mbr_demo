BITS 16
	
%define NPOINTS 	0x80
%define SCALE		0x40

%define XC	WORD [ebp-4]
%define YC	WORD [ebp-8]
%define T	WORD [ebp-12]
%define A	WORD [ebp-16]
%define B	WORD [ebp-20]
;%define RES	WORD [ebp-24]
;%define DF	WORD [ebp-24]
	DF	db ''
	RES 	db ''

	
init:
	;; setup local variables
	mov esp,ebp
	sub esp,32		

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

	mov A,0x1
	mov B,0x2
	mov XC,SCALE
	mov YC,SCALE

	;; draw the curve	
	;; 	mov cx,NPOINTS

	xor dx,dx
	inc dx
	mov DF,word dx

	mov cx,0x140
_loop_lis:
%if 0
	mov T,cx
	call p_calc_x	
	mov bx,RES
	call p_calc_y
%endif
 	call p_calc_sin

	mov ax,RES		;ax = y
	mov bx,cx		;bx = x
	
	add ax,0x64 		;align to center

	mov dx,0x140
	mul dx
	add bx,ax
	
	mov al,0x1
	mov byte [bx],al
	
	dec cx
	jnz _loop_lis
	
;;; stop
_wait_forever:
	jmp _wait_forever	

%if 0
;;; calculate X for the lissajous curve
;;; x = XC * sin (t*a*2pi/npoints)
p_calc_x:
	fldpi			;push pi
	
	mov [esp],word 0x2
	fild word [esp]		;push 2

	fmulp st1,st0		;2*pi
	
	fild A			;push a
	fild T			;push t
	fmulp st1,st0 		;a*t

	mov [esp], word NPOINTS 
	fild word [esp]		;push npoints	
	fdivp st1,st0		;(a*t)/npoints

	fmulp st1,st0		;(2*pi)*(a*t)/npoints = g
	
	fsin			;sin(g)
	fild XC			;push XC
	fmulp st1,st0		;XC*sin(g)
	fistp word RES		;pop RES

	ret
	
;;; calculate Y for the lissajous curve
;;; y = YC * sin (t*b*2pi/npoints)
p_calc_y:
	fldpi			;push pi
	
	mov [esp],word 0x2
	fild word [esp]		;push 2

	fmulp st1,st0		;2*pi
	
	fild B			;push b
	fild T			;push t
	fmulp st1,st0 		;b*t

	mov [esp], word NPOINTS
	fild word [esp] 	;push npoints
	fdivp st1,st0		;(b*t)/npoints

	fmulp st1,st0		;(2*pi)*(b*t)/npoints = h
	
	fsin			;sin(h)
	fild YC			;push YC
	fmulp st1,st0		;XY*sin(h)
	fistp word RES		;pop RES

	ret
%endif
	
;;; calculate the sin
p_calc_sin:
	fldpi			;push pi to fp stack

	mov [esp],word 0x2
	fild word [esp]		;push 2 to fp stack

	fmulp st1,st0		;pi*2
	
	fild word DF			;push df to fp stack

	mov [esp], word NPOINTS
	fild word [esp]		;push NPOINTS to fp stack
	
	fdivp st1,st0		;df/NPOINTS

	fmulp st1,st0		;(pi*2)*(df/NPOINTS)

	mov dx,DF		;update div factor (df)
	inc dx
	mov DF,dx

	fsin			;sin(pi*2/a)
	
	mov word [esp],SCALE
	fild word [esp]
	fmulp st1, st0		;expand the result for plotting
	
	fistp word RES		;pop x from fp stack
	ret
	
times 446 - ($ - $$) db 'U' 	;padding
times 64 db 'x' 		;partition table
db 0x55,0xaa
