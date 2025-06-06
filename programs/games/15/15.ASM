;
;   The famous game 15
;   Author: Lloyd, coded by Ivushkin Andrey
;   Compile with FASM
;

include 'lang.inc' ; Language support for locales: ru_RU (CP866), it_IT, de_DE, en_US.
include '..\..\macros.inc' ; decreases program size (not required)

StatusColor equ 0x00ffffff
StatusColor2 equ 0x00dc1e14
BgdColor equ 0x14aabbcc

; Main window dimensions
XXwindow equ 200 shl 16+276
YYwindow equ 200 shl 16+300
; Status bar
XYstatus equ 35 shl 16+283
XXbar equ 35 shl 16+136
YYbar equ 280 shl 16+15
; Buttons
BtnTop equ 28
BtnLeft equ 13
BtnSize equ 60
BtnColor equ 0xafbb55
BtnColor2 equ 0x0228c314

NumColor equ 0x10000000
; Number shifting for nice look
NumShift equ 23 shl 16+23
NumShift2 equ 4 shl 16
; Shuffle button
XXSh equ 202 shl 16+60
YYSh equ 280 shl 16+12
XYShText equ 212 shl 16+283

; Conf button
XXCnf equ 13 shl 16+13
YYCnf equ 280 shl 16+12
XYCnfText equ 18 shl 16+283

; Position of the 'hole'
null equ (curconf+16)
; Amount of moves to perform shuffle
SH_CYCLES equ 400
; (Amount of tasks)-1
CONF_COUNT equ 2

use32

  org    0x0

  db     'MENUET01'
  dd     0x01
  dd     START
  dd     I_END
  dd     0x2000  ; 8 Kb
  dd     0x2000
  dd     0x0
  dd     0x0


START:
    mov  [cptr],CONF_COUNT  ; number of task
    mov  eax,3
    mcall
    mov  cl,16
    ror  eax,cl
    mov  [generator],eax    ; random generator from Tetris
  init:
    mov  ecx,17
    movzx  eax,[cptr]
    inc  eax
    cmp  eax,CONF_COUNT
    jna  init_ok
    xor  eax,eax            ; cycling 0..CONF_COUNT
  init_ok:
    mov  [cptr],al
    mov  esi,eax
    shl  esi,4
    add  esi,conf
    add  esi,eax
    add  al,0x31
    mov  [txtTitle+17],al     ;task number to program title
    mov  [task],esi
    mov  edi,curconf
    rep  movsb          ; initial configuration

    mov  [sts],4
    jmp  red
SHUF:
    call shuffle        ; immediate shuffle
red:                    ; window redraw

    call draw_window

still:                  ; MAIN PROGRAM CYCLE

    mov  eax,10         ; wait for event
    mcall

    cmp  eax,1          ; redraw? -
    je   red            ; goto red
    cmp  eax,2          ; key pressed? -
    je   key            ; goto key
    cmp  eax,3          ; button pressed? -
    je   button         ; goto button

    jmp  still          ; no more events to process

  key:                  ; Key pressed
    mov  eax,2
    mcall
    shr  eax,8
    cmp  eax,32         ; <Space> = Shuffle
    je   SHUF
    cmp  eax,13         ; <Enter> = Choose task
    je   init
    cmp  eax,176
    jl   still
    sub  eax,176
    cmp  eax,3
    ja   still
    movzx eax,byte [eax+correct] ; 'delta' value from correct[]
    jmp  m_check

  button:              ; Button pressed
    mov  eax,17
    mcall
    shr  eax,8
    sub  eax,2

    cmp  eax,-1        ; id == 1 (closeme)?
    jne  noclose
    mcall

  noclose:
    jl   SHUF          ; Shuffle (id=0) pressed
    cmp  eax,18
    je   init          ; Conf button pressed
    sub  al,byte [null]
    mov  edi,correct
    mov  ecx,4
    repne scasb        ; checking for valid move-part 1
    jne  fail
  m_check:
    cmp  byte[sts],4 ; puzzle completed, blocking buttons
    ja   still
    call move_check    ; checking for valid move-part 2
    jnc  fail
    inc  [move_count]
    call draw_moves
fail:
    jmp  still          ; �����頥���

;   *******************************
;   *******  WINDOW DRAWING *******
;   *******************************

draw_window:

    mcall 12, 1 ; begin draw
	mcall 0, XXwindow, YYwindow, BgdColor,, txtTitle ; CREATING WINDOW


    mov  eax,8                     ; SHUFFLE BUTTON
    mov  ebx,XXSh
    mov  ecx,YYSh
    xor  edx,edx
    mov  esi,BtnColor
    mcall

    mov  ebx,XXCnf                  ; CONF BUTTON
    mov  ecx,YYCnf
    mov  edx,20
    ;mov  esi,BtnColor
    mcall

    mov  ebx, XYShText             ; SHUFFLE TEXT
    mov  ecx, StatusColor
    mov  edx,txtSh
    mov  esi,lenSh-txtSh
    mov  eax,4
    mcall

    mov  ebx, XYCnfText             ; CONF TEXT
    mov  edx,lenVictory-1
    mov  esi,1
    mcall

    mov  ecx, 16                   ; FIELD BUTTONS
  dbut:
    call draw_button
    loop dbut

    call draw_moves

    mcall 12, 2 ; end of drawing
    ret


;   *********************************************
;   ******* DRAWING A FIELD BUTTON **************
;   *********************************************
;   ECX - button number

draw_button:
    pusha
    dec  ecx
  ; calculating button dimensions
    mov  edi, ecx
    lea  edx,[ecx+2]
    mov  ebx,ecx
    and  ebx,11b
    shr  ecx,2

    imul ebx,BtnSize+3
    add  ebx,BtnLeft
    shl  ebx,16
    add  ebx,BtnSize

    imul ecx,BtnSize+3
    add  ecx,BtnTop
    shl  ecx,16
    add  ecx,BtnSize
    movzx eax,byte [null]
    cmp  eax,edi
    jne   no_hole

    pusha
    inc  ebx
    inc  ecx
    mov  edx,BgdColor
    mov  eax,13         ; clearing - 'hole'
    mcall
    popa

    or   edx,0x80000000 ; and removing button under it
no_hole:
    mov  al,byte[edi+curconf]
    mov  esi,[task]
    cmp  al,byte[edi+esi]
    je   highlight
    mov  esi,BtnColor
    jmp  s_rbutton
highlight:
    mov  esi,BtnColor2
s_rbutton:
    mov  eax,8          ; set/remove button
    mcall
    movzx eax,byte [null]
    cmp  eax,edi
    je   no_text        ; no digits - that's hole
    mov  edx,ebx
    shr  ecx,16
    mov  dx,cx
    add  edx,NumShift
    mov  ebx,0x20000
    movzx  ecx,byte [edi+curconf]
    cmp  ecx,9
    ja   two_num
    add  edx,NumShift2    ; shift to center digits
    sub  ebx,0x10000
two_num:
    mov  esi,NumColor
    mov  eax,47
    mcall
no_text:
    popa
    ret


;   *********************************************
;   ******* DRAWING STATUS LINE *****************
;   *********************************************

draw_moves:
    mov  eax, 13          ; clear area
    mov  ebx, XXbar
    mov  ecx, YYbar
    mov  edx, BgdColor
    mcall

    mov  eax, 4
    mov  ebx, XYstatus
    mov  ecx, StatusColor
    cmp  ax, [sts]
    jl   report_victory
    jne  report_moves
    mov  edx,txtCnf  ; prompt to choose configuration
    mov  esi,lenCnf-txtCnf
    jmp  e_dm
  report_moves:
    mov  edx,txtMoves  ; how many moves done
    mov  esi,lenMoves-txtMoves
    mov  eax,4
    mcall
    mov  esi,ecx
    mov  edx,ebx
    add  edx, 40 shl 16
    mov  ebx,0x030000
    movzx  ecx, byte[move_count]
    mov  eax,47
    jmp  e_dm
  report_victory:               ; puzzle completed
    mov  ecx,StatusColor2
    mov  edx,txtVictory
    mov  esi,lenVictory-txtVictory
  e_dm:
    mcall
    ret


;   *********************************************
;   ********* SHUFFLE ***************************
;   *********************************************

shuffle:
    xor  eax,eax
    mov  [sts],ax
    mov  [move_count],ax   ; reset moves to 0
    mov  [sh_off],al
    mov  eax, [generator]

    mov  ecx,SH_CYCLES
 sh_cycle:
    sub  eax,0x43ab45b5    ; next random number
    ror  eax,1
    xor  eax,0x32c4324f
    ror  eax,1
    mov  [generator],eax

    push eax
    and  eax,11b           ; direction 0..3
    movzx eax,byte [eax+correct]
    call move_check
    pop  eax
    jnc  sh_cycle          ; if fails then retry
    loop sh_cycle
    inc  byte[sh_off]          ; shuffling complete
    ret


;   *********************************************
;   ********* MOVE VALIDITY CHECK ***************
;   *********************************************
;   AL - 'DELTA' DIRECTION

move_check:
    pusha
    mov  ah,byte [null]
    mov  bx,ax
    cmp  bh,3
    ja   no_top
    cmp  al,-4       ; top of field
    je   no_move
no_top:
    cmp  bh,12
    jb   no_bottom
    cmp  al,4        ; bottom of field
    je   no_move
no_bottom:
    and  bh,11b
    cmp  bh,0
    jnz  no_left
    cmp  al,-1       ; left of field
    je  no_move
no_left:
    cmp  bh,11b
    jnz  ok
    cmp  al,1        ; right of field
    je  no_move
ok:
    mov bx,ax
    add bh,bl        ; bh-new hole
    mov byte [null],bh
    movzx ecx,ah
    mov al,byte[ecx+curconf]
    movzx edx,bh
    mov bl,byte[edx+curconf] ; swapping button & hole
    mov byte[ecx+curconf],bl
    mov byte[edx+curconf],al

    cmp  byte[sh_off],0  ; if shuffle in progress,
    jz   no_win      ; then no redraw

  ; drawing button & hole
    inc  ecx
    call draw_button
    movzx ecx,bh
    inc  ecx
    call draw_button
  ; testing if task completed
    mov  esi,[task]
    mov  edi,curconf
    mov  ecx,16
    repe cmpsb
    cmp  ecx,0
    jne  no_win
    mov  word[sts],6  ; puzzle done. Victory!
no_win:
    popa
    stc
    ret
no_move:
    popa
    clc
    ret
; this is deprecated debug routine
;ud:
;    ud2

; These are data used by program

correct db 1,-4,4,-1

conf db 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,15
     db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0
     db 1,2,3,4,12,13,14,5,11,0,15,6,10,9,8,7,9

txtMoves:
if lang eq ru_RU
     db '�����:'
else if lang eq it_IT
     db 'Movimenti:'
else if lang eq de_DE
     db 'Bewegungen:'
else ; Default to en_US
     db 'Moves:'
end if
lenMoves:

txtSh:
if lang eq ru_RU
     db '��ᮢ��'
else if lang eq it_IT
     db 'Mischia'
else if lang eq de_DE
     db 'Mischen'
else ; Default to en_US
     db 'Shuffle'
end if
lenSh:

txtCnf:
if lang eq ru_RU
     db '�롥�� ������ � ������->'
else if lang eq it_IT
     db 'Seleziona un compito, poi premi->'
else if lang eq de_DE
     db 'Waehle eine Aufgabe, dann clicke au->'
else ; Default to en_US
     db 'Select task, then press ->'
end if
lenCnf:

txtTitle:              ; ��ப� ���������
if lang eq ru_RU
     db   '��� 15 - ����� X', 0
else if lang eq it_IT
     db 'Gioco del quindici - partita X', 0
else if lang eq de_DE
     db '15-Puzzle - Spiel X', 0
else ; Default to en_US
     db   'Game 15 - puzzle X', 0
end if

txtVictory:
if lang eq ru_RU
     db '�� �訫� ������! ������->'
else if lang eq it_IT
     db 'Gioco completato! Premi ->'
else if lang eq de_DE
     db 'Spiel beendet! Druecken sie auf ->'
else ; Default to en_US
     db 'Puzzle completed!   Press->'
end if
lenVictory:

arrow equ lenVictory-2

I_END:  ; ����� �ணࠬ��
;null db ?
move_count dw ?
cptr db ?
sts dw ?
sh_off db ?
task dd ?
generator dd ?
curconf:
