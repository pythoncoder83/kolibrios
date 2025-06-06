;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                              ;;
;; Copyright (C) KolibriOS team 2007-2024. All rights reserved. ;;
;; Distributed under terms of the GNU General Public License    ;;
;;                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Virtual-8086 mode manager
; diamond, 2007, 2008

DEBUG_SHOW_IO = 0

struct  V86_machine
; page directory
        process         dd ?
; mutex to protect all data from writing by multiple threads at one time
        mutex           dd ?
; i/o permission map
        iopm            dd ?
ends

; Create V86 machine
; in: nothing
; out: eax = handle (pointer to struc V86_machine)
;      eax = NULL => failure
; destroys: ebx, ecx, edx (due to malloc)
v86_create:
; allocate V86_machine structure
        mov     eax, sizeof.V86_machine
        call    malloc
        test    eax, eax
        jz      .fail
; initialize mutex
        and     dword [eax + V86_machine.mutex], 0
; allocate tables
        mov     ebx, eax

        stdcall create_process, 4096
        test    eax, eax
        jz      .fail2

        mov     [eax + PROC.mem_used], 4096
        mov     [ebx + V86_machine.process], eax

        push    2000h
        call    kernel_alloc
        test    eax, eax
        jz      .fail2

        mov     [ebx + V86_machine.iopm], eax

; initialize tables
        push    edi
        mov     edi, eax
        mov     eax, -1
        mov     ecx, 2000h/4
        rep stosd

        mov     eax, [ebx + V86_machine.process]
        mov     eax, [eax + PROC.pdt_0_phys]

        pushfd
        cli
        mov     cr3, eax

; now V86 specific: initialize known addresses in first Mb

; first page - BIOS data (shared between all machines!)
; physical address = 0
; linear address = OS_BASE
; page before 0xA0000 - Extended BIOS Data Area (shared between all machines!)
; physical address = 0x9C000
; linear address = 0x8009C000
; (I have seen one computer with EBDA segment = 0x9D80,
; all other computers use less memory)

        mov     eax, PG_UWR
        mov     [page_tabs], eax
        invlpg  [eax]

        mov     byte [0x500], 0xCD
        mov     byte [0x501], 0x13
        mov     byte [0x502], 0xF4
        mov     byte [0x503], 0xCD
        mov     byte [0x504], 0x10
        mov     byte [0x505], 0xF4

        mov     eax, 0x98000+PG_UWR
        mov     edi, page_tabs+0x98*4
        mov     edx, 0x1000
        mov     ecx, 8
@@:
        stosd
        add     eax, edx
        loop    @b

; addresses 0xC0000 - 0xFFFFF - BIOS code (shared between all machines!)
; physical address = 0xC0000

        mov     eax, 0xC0000+PG_UWR
        mov     edi, page_tabs+0xC0*4
        mov     ecx, 64
@@:
        stosd
        add     eax, edx
        loop    @b

        mov     eax, [sys_proc + PROC.pdt_0_phys]
        mov     cr3, eax
        popfd

        pop     edi

        mov     eax, ebx
        ret
.fail2:
        mov     eax, ebx
        call    free
.fail:
        xor     eax, eax
        ret

;not used
; Destroy V86 machine
; in: eax = handle
; out: nothing
; destroys: eax, ebx, ecx, edx (due to free)
;v86_destroy:
;        push    eax
;        stdcall kernel_free, [eax+V86_machine.pagedir]
;        pop     eax
;        jmp     free

; Translate V86-address to linear address
; in: eax=V86 address
;     esi=handle
; out: eax=linear address
; destroys: nothing
v86_get_lin_addr:
        push    ecx edx
        mov     ecx, eax
        shr     ecx, 12
        mov     edx, [page_tabs + ecx*4]
        and     eax, 0xFFF
        and     edx, 0xFFFFF000
        or      eax, edx
        pop     edx ecx
        ret

;not used
; Sets linear address for V86-page
; in: eax=linear address (must be page-aligned)
;     ecx=V86 page (NOT address!)
;     esi=handle
; out: nothing
; destroys: nothing
;v86_set_page:
;        push    eax ebx
;        mov     ebx, [esi+V86_machine.pagedir]
;        mov     [ebx+ecx*4+0x1800], eax
;        call    get_pg_addr
;        or      al, 111b
;        mov     [ebx+ecx*4+0x1000], eax
;        pop     ebx eax
;        ret

; Allocate memory in V86 machine
; in: eax=size (in bytes)
;     esi=handle
; out: eax=V86 address, para-aligned (0x10 multiple)
; destroys: nothing
; Unfinished !!!
;v86_alloc:
;        push    ebx ecx edx edi
;        lea     ebx, [esi+V86_machine.mutex]
;        call    wait_mutex
;        add     eax, 0x1F
;        shr     eax, 4
;        mov     ebx, 0x1000  ; start with address 0x1000 (second page)
;        mov     edi, [esi+V86_machine.tables]
;.l:
;        mov     ecx, ebx
;        shr     ecx, 12
;        mov     edx, [edi+0x1000+ecx*4] ; get linear address
;        test    edx, edx                ; page allocated?
;        jz      .unalloc
;        mov     ecx, ebx
;        and     ecx, 0xFFF
;        add     edx, ecx
;        cmp     dword [edx], 0          ; free block?
;        jnz     .n
;        cmp     dword [edx+4],
;        and     [esi+V86_machine.mutex], 0
;        pop     edi edx ecx ebx
;        ret

uglobal
sys_v86_machine dd      ?
endg

; Called from kernel.asm at first stages of loading
; Initialize system V86 machine (used to simulate BIOS int 13h)
init_sys_v86:
        call    v86_create
        mov     [sys_v86_machine], eax
        test    eax, eax
        jz      .ret
        mov     esi, eax
if ~DEBUG_SHOW_IO
; allow access to all ports
        mov     ecx, [esi + V86_machine.iopm]
        xor     eax, eax
        mov     edi, ecx
        mov     ecx, 10000h/8/4
        rep stosd
end if
.ret:
        ret

struct  v86_regs
; don't change the order, it is important
        edi             dd ?
        esi             dd ?
        ebp             dd ?
                        dd ?    ; ignored
        ebx             dd ?
        edx             dd ?
        ecx             dd ?
        eax             dd ?
        eip             dd ?
        cs              dd ?
        eflags          dd ?    ; VM flag must be set!
        esp             dd ?
        ss              dd ?
        es              dd ?
        ds              dd ?
        fs              dd ?
        gs              dd ?
ends

; Run V86 machine
; in: ebx -> registers for V86 (two structures: in and out)
;     esi = handle
;     ecx = expected end address (CS:IP)
;     edx = IRQ to hook or -1 if not required
; out: structure pointed to by ebx is filled with new values
;     eax = 1 - exception has occured, cl contains code
;     eax = 2 - access to disabled i/o port, ecx contains port address
;     eax = 3 - IRQ is already hooked by another VM
; destroys: nothing
v86_start:

        pushad

        cli

        mov     ecx, [current_slot]

        push    dword [ecx + APPDATA.io_map]
        push    dword [ecx + APPDATA.io_map+4]
        push    [ecx + APPDATA.process]
        push    [ecx + APPDATA.saved_esp0]
        mov     [ecx + APPDATA.saved_esp0], esp
        mov     [tss._esp0], esp

        mov     eax, [esi + V86_machine.iopm]
        call    get_pg_addr
        inc     eax
        mov     dword [ecx + APPDATA.io_map], eax
        mov     dword [page_tabs + (tss._io_map_0 shr 10)], eax

        mov     eax, [esi + V86_machine.iopm]
        add     eax, 0x1000
        call    get_pg_addr
        inc     eax
        mov     dword [ecx + APPDATA.io_map + 4], eax
        mov     dword [page_tabs + (tss._io_map_1 shr 10)], eax

        mov     eax, [esi + V86_machine.process]
        mov     [ecx + APPDATA.process], eax
        mov     [current_process], eax
        mov     eax, [eax + PROC.pdt_0_phys]
        mov     cr3, eax

; We do not enable interrupts, because V86 IRQ redirector assumes that
; machine is running
; They will be enabled by IRET.
;        sti

        mov     eax, esi
        sub     esp, sizeof.v86_regs
        mov     esi, ebx
        mov     edi, esp
        mov     ecx, sizeof.v86_regs/4
        rep movsd

        cmp     edx, -1
        jz      .noirqhook
uglobal
v86_irqhooks    rd      IRQ_RESERVED * 2
endg
        cmp     [v86_irqhooks + edx*8], 0
        jz      @f
        cmp     [v86_irqhooks + edx*8], eax
        jz      @f
        mov     esi, v86_irqerr
        call    sys_msg_board_str
        inc     [v86_irqhooks + edx*8 + 4]
        mov     eax, 3
        jmp     v86_exc_c.exit
@@:
        mov     [v86_irqhooks + edx*8], eax
        inc     [v86_irqhooks + edx*8 + 4]
.noirqhook:

        popad
        iretd

; It is only possible to leave virtual-8086 mode by faulting to
; a protected-mode interrupt handler (typically the general-protection
; exception handler, which in turn calls the virtual 8086-mode monitor).

iglobal
  v86_exc_str1  db      'V86 : unexpected exception ',0
  v86_exc_str2  db      ' at ',0
  v86_exc_str3  db      ':',0
  v86_exc_str4  db      13,10,'V86 : faulted code:',0
  v86_exc_str5  db      ' (unavailable)',0
  v86_newline   db      13,10,0
  v86_io_str1   db      'V86 : access to disabled i/o port ',0
  v86_io_byte   db      ' (byte)',13,10,0
  v86_io_word   db      ' (word)',13,10,0
  v86_io_dword  db      ' (dword)',13,10,0
  v86_irqerr    db      'V86 : IRQ already hooked',13,10,0
endg

v86_exc_c:
; Did we all that we have wanted to do?
        cmp     bl, 1
        jne     @f
        xor     eax, eax
        mov     dr6, eax
  @@:
        mov     eax, [esp + sizeof.v86_regs + 10h+18h]
        cmp     word [esp + v86_regs.eip], ax
        jnz     @f
        shr     eax, 16
        cmp     word [esp + v86_regs.cs], ax
        jz      .done
@@:
; Various system events, which must be handled, result in #GP
        cmp     bl, 13
        jnz     .nogp
; If faulted EIP exceeds 0xFFFF, we have #GP and it is an error
        cmp     word [esp + v86_regs.eip+2], 0
        jnz     .nogp
; Otherwise we can safely access byte at CS:IP
; (because it is #GP, not #PF handler)
; If we could get an exception just because of reading code bytes,
; we would have got it already and it wouldn't be #GP
        movzx   esi, word [esp + v86_regs.cs]
        shl     esi, 4
        add     esi, [esp + v86_regs.eip]
        lodsb
        cmp     al, 0xCD        ; int xx command = CD xx
        jz      .handle_int
        cmp     al, 0xCF
        jz      .handle_iret
        cmp     al, 0xF3
        jz      .handle_rep
        cmp     al, 0xEC
        jz      .handle_in
        cmp     al, 0xED
        jz      .handle_in_word
        cmp     al, 0xEE
        jz      .handle_out
        cmp     al, 0xEF
        jz      .handle_out_word
        cmp     al, 0xE4
        jz      .handle_in_imm
        cmp     al, 0xE6
        jz      .handle_out_imm
        cmp     al, 0x9C
        jz      .handle_pushf
        cmp     al, 0x9D
        jz      .handle_popf
        cmp     al, 0xFA
        jz      .handle_cli
        cmp     al, 0xFB
        jz      .handle_sti
        cmp     al, 0x66
        jz      .handle_66
        jmp     .nogp
.handle_int:
        cmp     word [esp + v86_regs.eip], 0xFFFF
        jae     .nogp
        xor     eax, eax
        lodsb
;        call    sys_msg_board_byte
; simulate INT command
; N.B. It is possible that some checks need to be corrected,
;      but at least in case of normal execution the code works.
.simulate_int:
        cmp     word [esp + v86_regs.esp], 6
        jae     @f
        mov     bl, 12          ; #SS exception
        jmp     .nogp
@@:
        movzx   edx, word [esp + v86_regs.ss]
        shl     edx, 4
        push    eax
        movzx   eax, word [esp + 4 + v86_regs.esp]
        sub     eax, 6
        add     edx, eax
        mov     eax, edx
        mov     esi, [esp + 4 + sizeof.v86_regs + 10h+4]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14          ; #PF exception
        jmp     .nogp
@@:
        lea     eax, [edx+5]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14          ; #PF exception
        jmp     .nogp
@@:
        sub     word [esp+4+v86_regs.esp], 6
        mov     eax, [esp+4+v86_regs.eip]
        cmp     byte [esp+1], 0
        jnz     @f
        inc     eax
        inc     eax
@@:
        mov     word [edx], ax
        mov     eax, [esp + 4 + v86_regs.cs]
        mov     word [edx+2], ax
        mov     eax, [esp + 4 + v86_regs.eflags]
        mov     word [edx+4], ax
        pop     eax
        mov     ah, 0
        mov     cx, [eax*4]
        mov     word [esp + v86_regs.eip], cx
        mov     cx, [eax*4+2]
        mov     word [esp + v86_regs.cs], cx
; note that interrupts will be disabled globally at IRET
        and     byte [esp + v86_regs.eflags+1], not 3 ; clear IF and TF flags
; continue V86 execution
        popad
        iretd
.handle_iret:
        cmp     word [esp + v86_regs.esp], 0x10000 - 6
        jbe     @f
        mov     bl, 12
        jmp     .nogp
@@:
        movzx   edx, word [esp + v86_regs.ss]
        shl     edx, 4
        movzx   eax, word [esp + v86_regs.esp]
        add     edx, eax
        mov     eax, edx
        mov     esi, [esp + sizeof.v86_regs + 10h+4]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14
        jmp     .nogp
@@:
        lea     eax, [edx+5]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14
        jmp     .nogp
@@:
        mov     ax, [edx]
        mov     word [esp + v86_regs.eip], ax
        mov     ax, [edx+2]
        mov     word [esp + v86_regs.cs], ax
        mov     ax, [edx+4]
        mov     word [esp + v86_regs.eflags], ax
        add     word [esp + v86_regs.esp], 6
        popad
        iretd
.handle_pushf:
        cmp     word [esp + v86_regs.esp], 1
        jnz     @f
        mov     bl, 12
        jmp     .nogp
@@:
        movzx   edx, word [esp + v86_regs.ss]
        shl     edx, 4
        mov     eax, [esp + v86_regs.esp]
        sub     eax, 2
        movzx   eax, ax
        add     edx, eax
        mov     eax, edx
        mov     esi, [esp + sizeof.v86_regs + 10h+4]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14          ; #PF exception
        jmp     .nogp
@@:
        lea     eax, [edx+1]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14
        jmp     .nogp
@@:
        sub     word [esp + v86_regs.esp], 2
        mov     eax, [esp + v86_regs.eflags]
        mov     [edx], ax
        inc     word [esp + v86_regs.eip]
        popad
        iretd
.handle_pushfd:
        cmp     word [esp + v86_regs.esp], 4
        jae     @f
        mov     bl, 12          ; #SS exception
        jmp     .nogp
@@:
        movzx   edx, word [esp + v86_regs.ss]
        shl     edx, 4
        movzx   eax, word [esp + v86_regs.esp]
        sub     eax, 4
        add     edx, eax
        mov     eax, edx
        mov     esi, [esp + sizeof.v86_regs + 10h+4]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14          ; #PF exception
        jmp     .nogp
@@:
        lea     eax, [edx+3]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14          ; #PF exception
        jmp     .nogp
@@:
        sub     word [esp + v86_regs.esp], 4
        movzx   eax, word [esp + v86_regs.eflags]
        mov     [edx], eax
        add     word [esp + v86_regs.eip], 2
        popad
        iretd
.handle_popf:
        cmp     word [esp + v86_regs.esp], 0xFFFF
        jnz     @f
        mov     bl, 12
        jmp     .nogp
@@:
        movzx   edx, word [esp + v86_regs.ss]
        shl     edx, 4
        movzx   eax, word [esp + v86_regs.esp]
        add     edx, eax
        mov     eax, edx
        mov     esi, [esp + sizeof.v86_regs+10h+4]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14          ; #PF exception
        jmp     .nogp
@@:
        lea     eax, [edx+1]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14
        jmp     .nogp
@@:
        mov     ax, [edx]
        mov     word [esp + v86_regs.eflags], ax
        add     word [esp + v86_regs.esp], 2
        inc     word [esp + v86_regs.eip]
        popad
        iretd
.handle_popfd:
        cmp     word [esp + v86_regs.esp], 0x10000 - 4
        jbe     @f
        mov     bl, 12
        jmp     .nogp
@@:
        movzx   edx, word [esp + v86_regs.ss]
        shl     edx, 4
        movzx   eax, word [esp + v86_regs.esp]
        add     edx, eax
        mov     eax, edx
        mov     esi, [esp + sizeof.v86_regs + 10h+4]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14
        jmp     .nogp
@@:
        lea     eax, [edx+3]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jae     @f
        mov     bl, 14
        jmp     .nogp
@@:
        mov     eax, [edx]
        mov     word [esp + v86_regs.eflags], ax
        add     word [esp + v86_regs.esp], 4
        add     word [esp + v86_regs.eip], 2
        popad
        iretd
.handle_cli:
        and     byte [esp + v86_regs.eflags+1], not 2
        inc     word [esp + v86_regs.eip]
        popad
        iretd
.handle_sti:
        or      byte [esp + v86_regs.eflags+1], 2
        inc     word [esp + v86_regs.eip]
        popad
        iretd
.handle_rep:
        cmp     word [esp + v86_regs.eip], 0xFFFF
        jae     .nogp
        lodsb
        cmp     al, 6Eh
        jz      .handle_rep_outsb
        jmp     .nogp
.handle_rep_outsb:
.handle_in:
.handle_out:
.invalid_io_byte:
        movzx   ebx, word [esp + v86_regs.edx]
        mov     ecx, 1
        jmp     .invalid_io
.handle_in_imm:
.handle_out_imm:
        cmp     word [esp + v86_regs.eip], 0xFFFF
        jae     .nogp
        lodsb
        movzx   ebx, al
        mov     ecx, 1
        jmp     .invalid_io
.handle_66:
        cmp     word [esp + v86_regs.eip], 0xFFFF
        jae     .nogp
        lodsb
        cmp     al, 0x9C
        jz      .handle_pushfd
        cmp     al, 0x9D
        jz      .handle_popfd
        cmp     al, 0xEF
        jz      .handle_out_dword
        cmp     al, 0xED
        jz      .handle_in_dword
        jmp     .nogp
.handle_in_word:
.handle_out_word:
        movzx   ebx, word [esp + v86_regs.edx]
        mov     ecx, 2
        jmp     .invalid_io
.handle_in_dword:
.handle_out_dword:
.invalid_io_dword:
        movzx   ebx, word [esp + v86_regs.edx]
        mov     ecx, 4
.invalid_io:
        mov     esi, v86_io_str1
        call    sys_msg_board_str
        mov     eax, ebx
        call    sys_msg_board_dword
        mov     esi, v86_io_byte
        cmp     ecx, 1
        jz      @f
        mov     esi, v86_io_word
        cmp     ecx, 2
        jz      @f
        mov     esi, v86_io_dword
@@:
        call    sys_msg_board_str
if DEBUG_SHOW_IO
        mov     edx, ebx
        mov     ebx, 200
        call    delay_hs
        mov     esi, [esp + v86_regs.size + 10h+4]
        mov     eax, [esi + V86_machine.iopm]
@@:
        btr     [eax], edx
        inc     edx
        loop    @b
        popad
        iretd
else
        mov     eax, 2
        jmp     .exit
end if
.nogp:

        mov     esi, v86_exc_str1
        call    sys_msg_board_str
        mov     al, bl
        call    sys_msg_board_byte
        mov     esi, v86_exc_str2
        call    sys_msg_board_str
        mov     ax, [esp+32+4]
        call    sys_msg_board_word
        mov     esi, v86_exc_str3
        call    sys_msg_board_str
        mov     ax, [esp+32]
        call    sys_msg_board_word
        mov     esi, v86_exc_str4
        call    sys_msg_board_str
        mov     ecx, 8
        movzx   edx, word [esp+32+4]
        shl     edx, 4
        add     edx, [esp+32]
@@:
        mov     esi, [esp+sizeof.v86_regs + 10h+4]
        mov     eax, edx
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jb      .nopage
        mov     esi, v86_exc_str3 - 2
        call    sys_msg_board_str
        mov     al, [edx]
        call    sys_msg_board_byte
        inc     edx
        loop    @b
        jmp     @f
.nopage:
        mov     esi, v86_exc_str5
        call    sys_msg_board_str
@@:
        mov     esi, v86_newline
        call    sys_msg_board_str
        mov     eax, 1
        jmp     .exit

.done:
        xor     eax, eax

.exit:
        mov     [esp + sizeof.v86_regs + 10h+1Ch], eax
        mov     [esp + sizeof.v86_regs + 10h+18h], ebx

        mov     edx, [esp + sizeof.v86_regs + 10h+14h]
        cmp     edx, -1
        jz      @f
        dec     [v86_irqhooks + edx*8 + 4]
        jnz     @f
        and     [v86_irqhooks + edx*8], 0
@@:

        mov     esi, esp
        mov     edi, [esi + sizeof.v86_regs + 10h+10h]
        add     edi, sizeof.v86_regs
        mov     ecx, sizeof.v86_regs/4
        rep movsd
        mov     esp, esi

        cli
        mov     ecx, [current_slot]
        pop     eax

        mov     [ecx + APPDATA.saved_esp0], eax
        mov     [tss._esp0], eax
        pop     eax
        mov     [ecx + APPDATA.process], eax
        mov     [current_process], eax
        pop     ebx
        mov     dword [ecx + APPDATA.io_map+4], ebx
        mov     dword [page_tabs + (tss._io_map_1 shr 10)], ebx
        pop     ebx
        mov     dword [ecx + APPDATA.io_map], ebx
        mov     dword [page_tabs + (tss._io_map_0 shr 10)], ebx
        mov     eax, [eax+PROC.pdt_0_phys]
        mov     cr3, eax
        sti

        popad
        ret

;my05:
;        mov     dx, 30C2h
;        mov     cx, 4
;.0:
;        in      al, dx
;        cmp     al, 0FFh
;        jz      @f
;        test    al, 4
;        jnz     .1
;@@:
;        add     dx, 8
;        in      al, dx
;        cmp     al, 0FFh
;        jz      @f
;        test    al, 4
;        jnz     .1
;@@:
;        loop    .0
;        ret
;.1:
;        or      al, 84h
;        out     dx, al
;.2:
;        mov     dx, 30F7h
;        in      al, dx
;        mov     byte [BOOT_VAR + 48Eh], 0FFh
;        ret

align 4
v86_irq:
; push irq/pushad/jmp v86_irq
; ebp = irq
        lea     esi, [esp + 1Ch]
        lea     edi, [esi+4]
        mov     ecx, 8
        std
        rep movsd
        cld
        mov     edi, ebp
        pop     eax
v86_irq2:
        mov     esi, [v86_irqhooks + edi*8]       ; get VM handle
        mov     eax, [esi + V86_machine.process]
        mov     ecx, [current_slot]
        cmp     [ecx + APPDATA.process], eax
        jnz     .notcurrent
        lea     eax, [edi+8]
        cmp     al, 10h
        mov     ah, 1
        jb      @f
        add     al, 60h
@@:
        jmp     v86_exc_c.simulate_int
.notcurrent:
        mov     ebx, SLOT_BASE + sizeof.APPDATA
        mov     ecx, [thread_count]
.scan:
        cmp     [ebx + APPDATA.process], eax
        jnz     .cont
        push    ecx
        mov     ecx, [ebx + APPDATA.saved_esp0]
        cmp     word [ecx - sizeof.v86_regs + v86_regs.esp], 6
        jb      .cont2
        movzx   edx, word [ecx - sizeof.v86_regs + v86_regs.ss]
        shl     edx, 4
        push    eax
        movzx   eax, word [ecx - sizeof.v86_regs + v86_regs.esp]
        sub     eax, 6
        add     edx, eax
        mov     eax, edx
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jb      .cont3
        lea     eax, [edx+5]
        call    v86_get_lin_addr
        cmp     eax, 0x1000
        jb      .cont3
        pop     eax
        pop     ecx
        jmp     .found
.cont3:
        pop     eax
.cont2:
        pop     ecx
.cont:
        add     ebx, 0x100
        loop    .scan
        mov     ecx, edi
        call    irq_eoi
        popad
        iretd
.found:
        mov     eax, [eax + PROC.pdt_0_phys]
        mov     cr3, eax
        mov     esi, [ebx + APPDATA.saved_esp0]
        sub     word [esi - sizeof.v86_regs + v86_regs.esp], 6
        mov     ecx, [esi - sizeof.v86_regs + v86_regs.eip]
        mov     word [edx], cx
        mov     ecx, [esi - sizeof.v86_regs + v86_regs.cs]
        mov     word [edx+2], cx
        mov     ecx, [esi - sizeof.v86_regs + v86_regs.eflags]
        mov     word [edx+4], cx
        lea     eax, [edi+8]
        cmp     al, 10h
        jb      @f
        add     al, 60h
@@:
        mov     cx, [eax*4]
        mov     word [esi - sizeof.v86_regs + v86_regs.eip], cx
        mov     cx, [eax*4+2]
        mov     word [esi - sizeof.v86_regs + v86_regs.cs], cx
        and     byte [esi - sizeof.v86_regs + v86_regs.eflags + 1], not 3
        call    update_counters
        call    find_next_task.found
        call    do_change_task
        popad
        iretd
