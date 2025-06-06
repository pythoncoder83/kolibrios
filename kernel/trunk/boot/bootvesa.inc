;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                              ;;
;; Copyright (C) KolibriOS team 2004-2024. All rights reserved. ;;
;; Distributed under terms of the GNU General Public License    ;;
;;                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


struc VBE_VGAInfo {
  .VESASignature          dd ?    ; char
  .VESAVersion            dw ?    ; short
  .OemStringPtr           dd ?    ; char *
  .Capabilities           dd ?    ; ulong
  .VideoModePtr           dd ?    ; ulong
  .TotalMemory            dw ?    ; short
  ; VBE 2.0+
  .OemSoftwareRev         db ?    ; short
  .OemVendorNamePtr       dw ?    ; char *
  .OemProductNamePtr      dw ?    ; char *
  .OemProductRevPtr       dw ?    ; char *
  .reserved               rb 222  ; char
  .OemData                rb 256  ; char
}

struc VBE_ModeInfo {
  .ModeAttributes         dw ?    ; short
  .WinAAttributes         db ?    ; char
  .WinBAttributes         db ?    ; char
  .WinGranularity         dw ?    ; short
  .WinSize                dw ?    ; short
  .WinASegment            dw ?    ; ushort
  .WinBSegment            dw ?    ; ushort
  .WinFuncPtr             dd ?    ; void *
  .BytesPerScanLine       dw ?    ; short
  .XRes                   dw ?    ; short
  .YRes                   dw ?    ; short
  .XCharSize              db ?    ; char
  .YCharSize              db ?    ; char
  .NumberOfPlanes         db ?    ; char
  .BitsPerPixel           db ?    ; char
  .NumberOfBanks          db ?    ; char
  .MemoryModel            db ?    ; char
  .BankSize               db ?    ; char
  .NumberOfImagePages     db ?    ; char
  .res1                   db ?    ; char
  .RedMaskSize            db ?    ; char
  .RedFieldPosition       db ?    ; char
  .GreenMaskSize          db ?    ; char
  .GreenFieldPosition     db ?    ; char
  .BlueMaskSize           db ?    ; char
  .BlueFieldPosition      db ?    ; char
  .RsvedMaskSize          db ?    ; char
  .RsvedFieldPosition     db ?    ; char
  .DirectColorModeInfo    db ?    ; char ; MISSED IN THIS TUTORIAL!! SEE ABOVE
  ; VBE 2.0+
  .PhysBasePtr            dd ?    ; ulong
  .OffScreenMemOffset     dd ?    ; ulong
  .OffScreenMemSize       dw ?    ; short
  ; VBE 3.0+
  .LinbytesPerScanLine    dw ?    ; short
  .BankNumberOfImagePages db ?    ; char
  .LinNumberOfImagePages  db ?    ; char
  .LinRedMaskSize         db ?    ; char
  .LinRedFieldPosition    db ?    ; char
  .LingreenMaskSize       db ?    ; char
  .LinGreenFieldPosition  db ?    ; char
  .LinBlueMaskSize        db ?    ; char
  .LinBlueFieldPosition   db ?    ; char
  .LinRsvdMaskSize        db ?    ; char
  .LinRsvdFieldPosition   db ?    ; char
  .MaxPixelClock          dd ?    ; ulong
  .res2                   rb 190  ; char
}

virtual at $A000
  vi VBE_VGAInfo
  mi VBE_ModeInfo
modes_table:
end virtual
cursor_pos  dw 0        ; temporary cursor storage
cursor_pos_old  dw 0
home_cursor dw 0        ; current shows rows a table
end_cursor  dw 0        ; end of position current shows rows a table
scroll_start dw 0       ; start position of scroll bar
scroll_end  dw 0        ; end position of scroll bar
long_v_table = 9        ; long of visible video table
size_of_step = 10
scroll_area_size = long_v_table - 2
int2str:
        dec     bl
        jz      @f
        xor     edx, edx
        div     ecx
        push    edx
        call    int2str
        pop     eax
    @@:
        or      al, 0x30
        mov     [ds:di], al
        inc     di
        ret

int2strnz:
        cmp     eax, ecx
        jb      @f
        xor     edx, edx
        div     ecx
        push    edx
        call    int2strnz
        pop     eax
    @@:
        or      al, 0x30
        mov     [es:di], al
        inc     di
        ret

;-------------------------------------------------------
;Write message about incorrect v_mode and write message about jmp on swith v_mode
v_mode_error:
        _setcursor 19,2
        mov     si, fatalsel
        call    printplain
        _setcursor 20,2
        mov     si, pres_key
        call    printplain
        xor     eax, eax
        int     16h
        jmp     cfgmanager.d
;-------------------------------------------------------
;



;-------------------------------------------------------
print_vesa_info:
        _setcursor 5,2

        mov     [es:vi.VESASignature], 'VBE2'
        mov     ax, 0x4F00
        mov     di, vi     ;0xa000
        int     0x10
        or      ah, ah
        jz      @f
        mov     [es:vi.VESASignature], 'VESA'
        mov     ax, $4F00
        mov     di, vi
        int     0x10
        or      ah, ah
        jnz     .exit
  @@:
        cmp     [es:vi.VESASignature], 'VESA'
        jne     .exit
        cmp     [es:vi.VESAVersion], 0x0100
        jb      .exit
        jmp     .vesaok2

  .exit:
        mov     si, novesa
        call    printplain
        ret

  .vesaok2:
        mov     ax, [es:vi.VESAVersion]
        add     ax, '00'

        mov     [s_vesa.ver], ah
        mov     [s_vesa.ver+2], al
        mov     si, s_vesa
        call    printplain

        _setcursor 4,2
        mov     si, word[es:vi.OemStringPtr]
        mov     di, si

        push    ds
        mov     ds, word[es:vi.OemStringPtr+2]
        call    printplain
        pop     ds

        ret
;-----------------------------------------------------------------------------

calc_vmodes_table:
        pushad

;        push    0
;        pop     es

        lfs     si, [es:vi.VideoModePtr]

        mov     bx, modes_table
;save no vesa mode of work 320x200, EGA/CGA 256 жўҐв®ў and 640x480, VGA 16 жўҐв®ў
        mov     word [es:bx], 640
        mov     word [es:bx+2], 480
        mov     word [es:bx+6], 0x13

        mov     word [es:bx+10], 640
        mov     word [es:bx+12], 480
        mov     word [es:bx+16], 0x12
        add     bx, 20
  .next_mode:
        mov     cx, word [fs:si]; mode number
        cmp     cx, -1
        je      .modes_ok.2

        mov     ax, 0x4F01
        mov     di, mi
        int     0x10

        or      ah, ah
        jnz     .modes_ok.2;vesa_info.exit

        test    [es:mi.ModeAttributes], 00000001b  ;videomode support ?
        jz      @f
        test    [es:mi.ModeAttributes], 00010000b  ;picture ?
        jz      @f
        test    [es:mi.ModeAttributes], 10000000b  ;LFB ?
        jz      @f

        cmp     [es:mi.BitsPerPixel], 16   ;List only supported videomodes (16, 24 and 32 bpp)
        jb      @f

; 16 bpp might actually be 15 bpp
        cmp     [es:mi.BitsPerPixel], 16
        jne     .l0
        cmp     [es:mi.GreenMaskSize], 5
        jne     .l0
;        mov     [es:mi.BitsPerPixel],15
        jmp     @f                         ; 15 bpp isnt supported ATM


.l0:
        cmp     [es:mi.XRes], 640
        jb      @f
        cmp     [es:mi.YRes], 480
        jb      @f
;        cmp     [es:mi.BitsPerPixel],8
;        jb      @f

        mov     ax, [es:mi.XRes]
        mov     [es:bx+0], ax              ; +0[2] : resolution X
        mov     ax, [es:mi.YRes]
        mov     [es:bx+2], ax              ; +2[2] : resolution Y
        mov     ax, [es:mi.ModeAttributes]
        mov     [es:bx+4], ax              ; +4[2] : attributes

        cmp     [s_vesa.ver], '2'
;        jb      .lp1
        jb      @f    ; We do not use Vesa 1.2 mode is now

        or      cx, 0x4000 ; use LFB
.lp1:
        mov     [es:bx+6], cx              ; +6 : mode number
        movzx   ax, byte [es:mi.BitsPerPixel]
        mov     word [es:bx+8], ax              ; +8 : bits per pixel
        add     bx, size_of_step                ; size of record

    @@:
        add     si, 2
        jmp     .next_mode

  .modes_ok.2:

        mov     word[es:bx], -1 ;end video table
        mov     word[end_cursor], bx    ;save end cursor position
;;;;;;;;;;;;;;;;;;
;Sort array
;        mov     si,modes_table
;.new_mode:
;        mov     ax,word [es:si]
;        cmp     ax,-1
;        je      .exxit
;        add     ax,word [es:si+2]
;        add     ax,word [es:si+8]
;        mov     bp,si
;.again:
;        add     bp,12
;        mov     bx,word [es:bp]
;        cmp     bx,-1
;        je      .exit
;        add     bx,word [es:bp+2]
;        add     bx,word [es:bp+8]
;
;        cmp     ax,bx
;        ja      .loops
;        jmp     .again
;.loops:
;        push    dword [es:si]
;        push    dword [es:si+4]
;        push    dword [es:si+8]
;        push    dword [es:bp]
;        push    dword [es:bp+4]
;        push    dword [es:bp+8]
;
;        pop     dword [es:si+8]
;        pop     dword [es:si+4]
;        pop     dword [es:si]
;        pop     dword [es:bp+8]
;        pop     dword [es:bp+4]
;        pop     dword [es:bp]
;        jmp     .new_mode
;
;.exit:  add     si,12
;        jmp     .new_mode
;.exxit:
        popad
        ret

;-----------------------------------------------------------------------------

draw_current_vmode:
        push    0
        pop     es

        mov     si, word [cursor_pos]

        cmp     word [es:si+6], 0x12
        je      .no_vesa_0x12

        cmp     word [es:si+6], 0x13
        je      .no_vesa_0x13

if defined extended_primary_loader
        mov     di, config_file_variables
else
        mov     di, loader_block_error
end if
        movzx   eax, word[es:si+0]
        mov     ecx, 10
        call    int2strnz
        mov     byte[es:di], 'x'
        inc     di
        movzx   eax, word[es:si+2]
        call    int2strnz
        mov     byte[es:di], 'x'
        inc     di
        movzx   eax, word[es:si+8]
        call    int2strnz
        mov     dword[es:di], 0x00000d0a
if defined extended_primary_loader
        mov     si, config_file_variables
else
        mov     si, loader_block_error
end if
        push    ds
        push    es
        pop     ds
        call    printplain
        pop     ds
        ret
.no_vesa_0x13:
        mov     si, mode0
        jmp     .print
.no_vesa_0x12:
        mov     si, mode9
.print:
        call    printplain
        ret
;-----------------------------------------------------------------------------
check_first_parm:
if defined extended_primary_loader
        mov     cx, [number_vm]
        jcxz    .novbemode
        mov     si, modes_table
.findvbemode:
        cmp     [es:si+6], cx
        jnz     @f
        cmp     word [es:si+8], 32
        je      .ok_found_mode
        cmp     word [es:si+8], 24
        je      .ok_found_mode
        cmp     word [es:si+8], 16
        je      .ok_found_mode
@@:
        add     si, size_of_step
        cmp     word [es:si], -1
        jnz     .findvbemode
.novbemode:
        mov     ax, [x_save]
        test    ax, ax
        jz      .zerro
        mov     bx, [y_save]
        mov     si, modes_table
        call    .loops
        test    ax, ax
        jz      .ok_found_mode
else
        mov     si, word [preboot_graph]
        test    si, si
        jnz     .no_zero         ;if no zero
end if
.zerro:
;        mov     ax,modes_table
;        mov     word [cursor_pos],ax
;        mov     word [home_cursor],ax
;        mov     word [preboot_graph],ax
;SET default video of mode first probe will fined a move of work 1024x768@32
        mov     cx, 32
  .find_mode:
        mov     ax, 1024
        mov     bx, 768
        mov     si, modes_table
        call    .loops
        test    ax, ax
        jz      .ok_found_mode
        mov     ax, 800
        mov     bx, 600
        mov     si, modes_table
        call    .loops
        test    ax, ax
        jz      .ok_found_mode
        mov     ax, 640
        mov     bx, 480
        mov     si, modes_table
        call    .loops
        test    ax, ax
        jz      .ok_found_mode
        sub     cx, 8
        jnz     .find_mode

        mov     si, modes_table
if ~ defined extended_primary_loader
        jmp     .ok_found_mode



.no_zero:
        mov     bp, word [number_vm]
        cmp     bp, word [es:si+6]
        jz      .ok_found_mode
        mov     ax, word [x_save]
        mov     bx, word [y_save]
        mov     si, modes_table
        call    .loops
        test    ax, ax
        jz      .ok_found_mode

        mov     si, modes_table
;        cmp     ax,modes_table
;        jb      .zerro           ;check on correct if bellow
;        cmp     ax,word [end_cursor]
;        ja      .zerro           ;check on correct if anymore
end if

.ok_found_mode:
        mov     word [home_cursor], si
;        mov     word [cursor_pos],si
        mov     word [preboot_graph], si
        mov     ax, si

        mov     ecx, long_v_table

.loop:
        add     ax, size_of_step
        cmp     ax, word [end_cursor]
        jae     .next_step
        loop    .loop
.next_step:
        sub     ax, size_of_step*long_v_table
        cmp     ax, modes_table
        jae     @f
        mov     ax, modes_table
@@:

        mov     word [home_cursor], ax
        mov     si, [preboot_graph]
        mov     word [cursor_pos], si

        push    word [es:si]
        pop     word [x_save]
        push    word [es:si+2]
        pop     word [y_save]
        push    word [es:si+6]
        pop     word [number_vm]

        ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;
.loops:
        cmp     ax, word [es:si]
        jne     .next
        cmp     bx, word [es:si+2]
        jne     .next
        jcxz    @f
        cmp     cx, word [es:si+8]
        jne     .next
@@:
        xor     ax, ax
        ret
.next:
        add     si, size_of_step
        cmp     word [es:si], -1
        je      .exit
        jmp     .loops
.exit:
        or      ax, -1
        ret


;-----------------------------------------------------------------------------

;default_vmode:

;-----------------------------------------------------------------------------
draw_vmodes_table:
        _setcursor 9, 2
        mov     si, gr_mode
        call    printplain

        mov     si, _st
        call    printplain

        push    word [cursor_pos]
        pop     ax
        push    word [home_cursor]
        pop     si
        mov     cx, si

        cmp     ax, si
        je      .ok
        jb      .low


        add     cx, size_of_step*long_v_table

        cmp     ax, cx
        jb      .ok

        sub     cx, size_of_step*long_v_table
        add     cx, size_of_step
        cmp     cx, word[end_cursor]
        jae     .ok
        add     si, size_of_step
        push    si
        pop     word [home_cursor]
        jmp     .ok


.low:
        sub     cx, size_of_step
        cmp     cx, modes_table
        jb      .ok
        push    cx
        push    cx
        pop     word [home_cursor]
        pop     si


.ok:
; calculate scroll position
        push    si
        mov     ax, [end_cursor]
        sub     ax, modes_table
        mov     bx, size_of_step
        cwd
        div     bx
        mov     si, ax          ; si = size of list
        mov     ax, [home_cursor]
        sub     ax, modes_table
        cwd
        div     bx
        mov     di, ax
        mov     ax, scroll_area_size*long_v_table
        cwd
        div     si
        test    ax, ax
        jnz     @f
        inc     ax
@@:
        cmp     al, scroll_area_size
        jb      @f
        mov     al, scroll_area_size
@@:
        mov     cx, ax
; cx = scroll height
; calculate scroll pos
        xor     bx, bx          ; initialize scroll pos
        sub     al, scroll_area_size+1
        neg     al
        sub     si, long_v_table-1
        jbe     @f
        mul     di
        div     si
        mov     bx, ax
@@:
        inc     bx
        imul    ax, bx, size_of_step
        add     ax, [home_cursor]
        mov     [scroll_start], ax
        imul    cx, size_of_step
        add     ax, cx
        mov     [scroll_end], ax
        pop     si
        mov     bp, long_v_table              ;show rows
.@@_next_bit:
;clear cursor
        mov     ax, '  '
        mov     word[ds:_r1+21], ax
        mov     word[ds:_r1+50], ax

        mov     word[ds:_r2+21], ax
        mov     word[ds:_r2+45], ax

        mov     word[ds:_rs+21], ax
        mov     word[ds:_rs+46], ax
; draw string
        cmp     word [es:si+6], 0x12
        je      .show_0x12
        cmp     word [es:si+6], 0x13
        je      .show_0x13

        movzx   eax, word[es:si]
        cmp     ax, -1
        je      .@@_end
        mov     di, _rs+23
        mov     ecx, 10
        mov     bl, 4
        call    int2str
        movzx   eax, word[es:si+2]
        inc     di
        mov     bl, 4
        call    int2str

        movzx   eax, word[es:si+8]
        inc     di
        mov     bl, 2
        call    int2str

        cmp     si, word [cursor_pos]
        jne     .next
;draw   cursor
        mov     word[ds:_rs+21], '>>'
        mov     word[ds:_rs+46], '<<'



.next:
        push    si
        mov     si, _rs
.@@_sh:
; add to the string pseudographics for scrollbar
        pop     bx
        push    bx
        mov     byte [si+53], ' '
        cmp     bx, [scroll_start]
        jb      @f
        cmp     bx, [scroll_end]
        jae     @f
        mov     byte [si+53], 0xDB ; filled bar
@@:
        push    bx
        add     bx, size_of_step
        cmp     bx, [end_cursor]
        jnz     @f
        mov     byte [si+53], 31 ; 'down arrow' symbol
@@:
        sub     bx, [home_cursor]
        cmp     bx, size_of_step*long_v_table
        jnz     @f
        mov     byte [si+53], 31 ; 'down arrow' symbol
@@:
        pop     bx
        cmp     bx, [home_cursor]
        jnz     @f
        mov     byte [si+53], 30 ; 'up arrow' symbol
@@:
        call    printplain
        pop     si
        add     si, size_of_step

        dec     bp
        jnz     .@@_next_bit

.@@_end:
        mov     si, _bt
        call    printplain
        ret
.show_0x13:
        push    si

        cmp     si, word [cursor_pos]
        jne     @f
        mov     word[ds:_r1+21], '>>'
        mov     word[ds:_r1+50], '<<'
@@:
        mov     si, _r1
        jmp     .@@_sh
.show_0x12:
        push    si
        cmp     si, word [cursor_pos]
        jne     @f

        mov     word[ds:_r2+21], '>>'
        mov     word[ds:_r2+45], '<<'
@@:
        mov     si, _r2
        jmp     .@@_sh

;-----------------------------------------------------------------------------
;Clear area of current video page (0xb800)
clear_vmodes_table:
        pusha
       ; draw frames
        push    es
        push    0xb800
        pop     es
        mov     di, 1444
        xor     ax, ax
        mov     ah, 1*16+15
        mov     cx, 77
        mov     bp, 12
.loop_start:
        rep stosw
        mov     cx, 77
        add     di, 6
        dec     bp
        jns     .loop_start
        pop     es
        popa
        ret

;-----------------------------------------------------------------------------

set_vmode:
        push    0 ;0;x1000
        pop     es

        mov     si, word [preboot_graph]        ;[preboot_graph]
        mov     cx, word [es:si+6]              ; number of mode


        mov     ax, word [es:si+0]              ; resolution X
        mov     bx, word [es:si+2]              ; resolution Y


        mov     word [es:BOOT_LO.x_res], ax     ; resolution X
        mov     word [es:BOOT_LO.y_res], bx     ; resolution Y
        mov     word [es:BOOT_LO.vesa_mode], cx ; number of mode

        cmp     cx, 0x12
        je      .mode0x12_0x13
        cmp     cx, 0x13
        je      .mode0x12_0x13


;        cmp     byte [s_vesa.ver], '2'
;        jb      .vesa12

;  VESA 2 and Vesa 3

        mov     ax, 0x4f01
        and     cx, 0xfff
        mov     di, mi;0xa000
        int     0x10
        ; LFB
        mov     eax, [es:mi.PhysBasePtr]        ; di+0x28
        mov     [es:BOOT_LO.lfb], eax
        ; ---- vbe voodoo
        BytesPerLine = 0x10
        mov     ax, [es:di+BytesPerLine]
        mov     [es:BOOT_LO.pitch], ax
        ; BPP
        cmp     [es:mi.BitsPerPixel], 16
        jne     .l0
        cmp     [es:mi.GreenMaskSize], 5
        jne     .l0
        mov     [es:mi.BitsPerPixel], 15
.l0:
        mov     al, byte [es:di+0x19]
        mov     [es:BOOT_LO.bpp], al
        jmp     .exit

.mode0x12_0x13:
        mov     byte [es:BOOT_LO.bpp], 32
        or      dword [es:BOOT_LO.lfb], 0xFFFFFFFF; 0x800000


;  VESA 1.2 PM BANK SWITCH ADDRESS

;.vesa12:
;        mov     ax, 0x4f0A
;        xor     bx, bx
;        int     0x10
;        xor     eax, eax
;        xor     ebx, ebx
;        mov     ax, es
;        shl     eax, 4
;        mov     bx, di
;        add     eax, ebx
;        movzx   ebx, word[es:di]
;        add     eax, ebx
;        push    0x0000
;        pop     es
;        mov     [es:BOOT_LO.bank_sw], eax
  .exit:
        ret

;=============================================================================
;=============================================================================
;=============================================================================

