;*****************************************************************************
; File Browser control for Kolibri OS
; Copyright (c) 2009-2013, Marat Zakiyanov aka Mario79, aka Mario
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;	 * Redistributions of source code must retain the above copyright
;	   notice, this list of conditions and the following disclaimer.
;	 * Redistributions in binary form must reproduce the above copyright
;	   notice, this list of conditions and the following disclaimer in the
;	   documentation and/or other materials provided with the distribution.
;	 * Neither the name of the <organization> nor the
;	   names of its contributors may be used to endorse or promote products
;	   derived from this software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY Marat Zakiyanov ''AS IS'' AND ANY
; EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL <copyright holder> BE LIABLE FOR ANY
; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;*****************************************************************************
;*****************************************************************************
macro	file_browser_exit
{
popa        
ret 4
}
;*****************************************************************************
fb_type				equ dword [edi]		;dword
fb_size_x			equ [edi+4]		;word
fb_start_x			equ [edi+6]		;word
fb_size_y			equ [edi+8]		;word
fb_start_y			equ [edi+10]		;word
fb_icon_size_y			equ word [edi+12]	;word
fb_icon_size_x			equ word [edi+14]	;word
fb_line_size_x			equ word [edi+16]	;word
fb_line_size_y			equ word [edi+18]	;word
fb_type_size_x			equ word [edi+20]	;word
fb_size_size_x			equ word [edi+22]	;word
fb_date_size_x			equ word [edi+24]	;word
fb_attributes_size_x		equ word [edi+26]	;word
fb_icon_assoc_area		equ dword [edi+28]	;dword
fb_icon_raw_area		equ dword [edi+32]	;dword
fb_resolution_raw		equ dword [edi+36]	;dword
fb_palette_raw			equ dword [edi+40]	;dword
fb_directory_path_area		equ dword [edi+44]	;dword
fb_file_name_area		equ dword [edi+48]	;dword
fb_select_flag			equ dword [edi+52]	;dword
fb_background_color		equ dword [edi+56]	;dword
fb_select_color			equ dword [edi+60]	;dword
fb_seclect_text_color		equ dword [edi+64]	;dword
fb_text_color			equ dword [edi+68]	;dword
fb_reduct_text_color		equ dword [edi+72]	;dword
fb_marked_text_color		equ dword [edi+76]	;dword
fb_max_panel_line		equ dword [edi+80]	;dword
fb_select_panel_counter		equ dword [edi+84]	;dword
fb_folder_block			equ dword [edi+88]	;dword
fb_start_draw_line		equ dword [edi+92]	;dword
fb_start_draw_cursor_line	equ word [edi+96]	;word
fb_folder_data			equ dword [edi+98]	;dword
fb_temp_counter			equ dword [edi+102]	;dword
fb_file_name_length		equ dword [edi+106]	;dword
fb_marked_file			equ dword [edi+110]	;dword
fb_extension_size		equ dword [edi+114]	;dword
fb_extension_start		equ dword [edi+118]	;dword
fb_type_table			equ dword [edi+122]	;dword
fb_ini_file_start		equ dword [edi+126]	;dword
fb_ini_file_end			equ dword [edi+130]	;dword
fb_draw_scroll_bar		equ dword [edi+134]	;dword
fb_font_size_y			equ word [edi+138]	;dword
fb_font_size_x			equ word [edi+140]	;dword
fb_mouse_keys			equ dword [edi+142]	;dword
fb_mouse_keys_old		equ dword [edi+146]	;dword
fb_mouse_pos			equ dword [edi+150]	;dword
fb_mouse_keys_delta		equ dword [edi+154]	;dword
fb_mouse_key_delay		equ dword [edi+158]	;dword
fb_mouse_keys_tick		equ dword [edi+162]	;dword
fb_start_draw_cursor_line_2	equ word [edi+166]	;dword
fb_all_redraw			equ dword [edi+168]	;dword
fb_selected_BDVK_adress		equ dword [edi+172]	;dword
fb_key_action			equ word [edi+176]	;word
fb_key_action_num		equ word [edi+178]	;word
fb_name_temp_area		equ dword [edi+180]	;dword
fb_max_name_temp_size		equ dword [edi+184]	;dword
fb_display_name_max_length	equ dword [edi+188]	;dword
fb_draw_panel_selection_flag	equ dword [edi+192]	;dword
fb_mouse_pos_old		equ dword [edi+196]	;dword
fb_marked_counter		equ dword [edi+200]	;dword
fb_keymap_pointer		equ dword [edi+204]	;dword
;---------------------------------------------------------------------
align 16
fb_draw_panel:
	pusha
	mov	edi,dword [esp+36]
	call	fb_clear_panel
	call	fb_calc_max_panel_line
	call	fb_calc_folder_sysdata
	call	fb_draw_panel_selection
	call	fb_draw_folder_data
	call	fb_prepare_selected_BDVK_adress
file_browser_exit
;---------------------------------------------------------------------
fb_draw_panel_1:
	pusha
	mov	eax,fb_select_color
	push	eax
	mov	eax,fb_seclect_text_color
	push	eax
	mov	ax,fb_start_draw_cursor_line
	push	eax
	mov	eax,fb_background_color
	mov	fb_select_color,eax
	mov	eax,fb_text_color
	mov	fb_seclect_text_color,eax
	mov	ax,fb_start_draw_cursor_line_2
	mov	fb_start_draw_cursor_line,ax
	call	fb_draw_panel_selection
	pop	eax
	mov	fb_start_draw_cursor_line,ax
	pop	eax
	mov	fb_seclect_text_color,eax
	pop	eax
	mov	fb_select_color,eax
	call	fb_draw_panel_selection
	call	fb_draw_folder_data
	popa
	ret
;---------------------------------------------------------------------
align 4
fb_clear_panel:
	cmp	fb_all_redraw,1
	jne	@f
	xor	eax,eax
	mov	fb_max_name_temp_size,eax
@@:
	ret
;---------------------------------------------------------------------
align 4
fb_calc_folder_sysdata:
	mov	eax,fb_folder_data
	mov	eax,[eax+4]
	mov	fb_folder_block,eax
	ret
;---------------------------------------------------------------------
align 4
fb_calc_max_panel_line:
	xor	eax,eax
	xor	ebx,ebx
	mov	ax,fb_size_y
	mov	bx,fb_line_size_y
	test	ebx,ebx
	jnz	@f
	inc	ebx
@@:
	xor	edx,edx
	div	ebx
	mov	fb_max_panel_line,eax
	ret
;---------------------------------------------------------------------
align 4
fb_draw_panel_selection:
	cmp	fb_all_redraw,2
	je	.end
	mov	eax,fb_folder_block
	test	eax,eax
	jz	.end
	xor	eax,eax
	cmp	fb_select_panel_counter,eax
	je	.end
	mov	eax,fb_folder_block
	sub	eax,fb_start_draw_line
	mov	cx,fb_start_draw_cursor_line
	call	fb_for_all_panel_selection
	mov	eax,fb_folder_block
	dec	eax
	xor	edx,edx
	mov	dx,fb_line_size_y
	imul	eax,edx
	cmp	ax,cx
	jae	@f
	mov	cx,ax
@@:
	mov	fb_start_draw_cursor_line,cx
	mov	ebx,fb_size_x
	add	cx,fb_start_y
	shl	ecx,16
	mov	cx,fb_line_size_y
	mov	edx,fb_select_color
	xor	eax,eax
	mov	ax,fb_icon_size_x
	add	eax,2
	sub	ebx,eax
	shl	eax,16
	push	eax
	add	ebx,eax
	mcall	SF_DRAW_RECT
	pop	ebx
	cmp	fb_all_redraw,0
	je	.end
	mov	bx,fb_start_x
	ror	ebx,16
	mcall	SF_DRAW_RECT,,,fb_background_color
.end:
	ret
;---------------------------------------------------------------------
align 4
fb_for_all_panel_selection:
	xor	edx,edx
	mov	dx,fb_line_size_y
	imul	eax,edx
	cmp	ax,cx
	jae	@f
	mov	cx,ax
@@:
	mov	eax,fb_max_panel_line
	dec	eax
	imul	eax,edx
	cmp	ax,cx
	jae	@f
	mov	cx,ax
@@:
	ret
;---------------------------------------------------------------------
align 4
fb_draw_folder_data:
	mov	eax,fb_folder_block
	sub	eax,fb_max_panel_line
	test	eax,0x80000000
	jz	.ok_left
	mov	fb_start_draw_line,0
	jmp	@f
.ok_left:
	cmp	eax,fb_start_draw_line
	jae	@f
	mov	fb_start_draw_line,eax
@@:
	mov	bx,fb_start_x
	add	bx,3
	add	bx,fb_icon_size_x
	shl	ebx,16
	mov	bx,fb_start_y
	mov	edx,fb_start_draw_line
	imul	edx,304
	add	edx,fb_folder_data
	add	edx,32+40
	xor	eax,eax
.start:
	pusha
	mov	eax,edx
	sub	eax,fb_folder_data
	sub	eax,32+40
	xor	edx,edx
	mov	ebx,304
	div	ebx
	cmp	eax,fb_folder_block
	je	.end_1
	popa
	cmp	eax,fb_max_panel_line
	je	.end_2
	mov	fb_marked_file,0
	cmp	[edx+299-40],byte 0
	je	@f
	mov	fb_marked_file,1
@@:
	call	fb_clear_line
	call	fb_draw_type_size_date
	cmp	fb_all_redraw,2
	je	.draw_icon
	cmp	fb_all_redraw,0
	je	@f
.draw_icon:
	call	fb_draw_icon
@@:
	push	eax
	xor	eax,eax
	mov	ax,fb_size_x
	push	ebx edx
	xor	ebx,ebx
	mov	bx,fb_font_size_x
	xor	edx,edx
	div	ebx
	pop	edx ebx
	sub	eax,23+2+2+2
	mov	esi,fb_file_name_length
	mov	fb_temp_counter,0
	mov	fb_display_name_max_length,eax
	cmp	esi,eax
	jbe	@f
	mov	esi,eax
	mov	fb_temp_counter,1
@@:
	cmp	fb_max_name_temp_size,esi
	jae	@f
	mov	fb_max_name_temp_size,esi
	inc	fb_max_name_temp_size
@@:
	mov	ecx,fb_text_color
	cmp	fb_marked_file,0
	je	@f
	mov	ecx,fb_reduct_text_color
@@:
	mov	ax,fb_line_size_y
	sub	ax,fb_font_size_y
	push	ebx
	mov	bx,ax
	shr	ax,1
	test	bx,1b
	jz	@f
	inc	ax
@@:
	pop	ebx
	push	ebx
	add	bx,ax
	call	.draw_name_temp_area
	cmp	fb_temp_counter,0
	jz	.continue
	xor	eax,eax
	mov	ax,fb_font_size_x
	imul	eax,fb_display_name_max_length
	shl	eax,16
	push	edx
	add	ebx,eax
	mov	esi,2
	mov	ecx,fb_reduct_text_color
	mov	edx,dword fb_truncated_filename_char
	mcall	SF_DRAW_TEXT
	pop	edx
.continue:
	pop	ebx
	add	bx,fb_line_size_y
	add	edx,304
	pop	eax
	inc	eax
	jmp	.start
;--------------------------------------
align 4
.draw_name_temp_area:
	pusha
	mov	eax,fb_max_name_temp_size
	add	eax,2
	sub	eax,esi
	mov	ecx,esi
	mov	esi,edx
	mov	edi,fb_name_temp_area
	cld
	jcxz	@f
	rep	movsb
	cmp	byte [edi-1],0
	jnz	@f
	dec	edi
	inc	eax
@@:
	mov	ecx,eax
	shr	ecx,2
	mov	eax,dword '    '
	rep	stosd
	popa
	pusha
	mov	edx,fb_name_temp_area
	cmp	fb_all_redraw,2
	jne	@f
	mov	esi,fb_max_name_temp_size
	add	esi,2
@@:
	bts	ecx,30
	mov	eax,fb_background_color
	cmp	fb_draw_panel_selection_flag,1
	jne	@f
	mov	eax,fb_select_color
@@:
	mov	edi,eax
	mcall	SF_DRAW_TEXT
	popa
	ret
;--------------------------------------
.end_1:
	popa
.end_2:
	cmp	fb_all_redraw,1
	jne	@f
	mov	ax,fb_start_y
	add	ax,fb_size_y
	mov	cx,bx
	rol	ecx,16
	mov	cx,ax
	mov	eax,ecx
	shr	eax,16
	sub	cx,ax
	cmp	cx,0
	jbe	@f
	mov	bx,fb_size_x
	ror	ebx,16
	sub	bx,fb_icon_size_x
	sub	bx,3
	rol	ebx,16
	mov	edx,fb_background_color	;0xffffff
	mcall	SF_DRAW_RECT
@@:
	ret
;---------------------------------------------------------------------
align 4
fb_clear_line:
	mov	fb_draw_panel_selection_flag,0
	pusha
	shl	ebx,16
	shr	ebx,16
	cmp	fb_select_panel_counter,0
	je	.continue
	mov	ax,fb_start_draw_cursor_line
	add	ax,fb_start_y
	cmp	bx,ax
	jne	.continue
	mov	fb_draw_panel_selection_flag,1
	jmp	.end
.continue:
	cmp	fb_all_redraw,2
	je	.end
	cmp	fb_all_redraw,0
	je	.end
	mov	ebx,[esp+16]
	mov	cx,bx
	rol	ecx,16
	mov	cx,fb_line_size_y
	mov	bx,fb_size_x
	ror	ebx,16
	sub	bx,fb_icon_size_x
	sub	bx,3
	rol	ebx,16
	mcall	SF_DRAW_RECT,,,fb_background_color
.end:
	popa
	ret
;---------------------------------------------------------------------
align 4
fb_draw_type_size_date:
	pusha
	mov	eax,fb_type_table
	test	[edx-40],byte 0x10
	jz	.copy_type
	mov	[eax],dword '<DIR'
	mov	[eax+4],word '> '
	mov	fb_file_name_length,0
	mov	fb_extension_size,0
	jmp	.start
.copy_type:
	mov	[eax],dword '    '
	mov	[eax+4],word '  '
.start:
	mov	esi,edx
	xor	eax,eax
@@:
	cld
	lodsb
	test	eax,eax
	jnz	@b
	mov	fb_file_name_length,esi
	sub	fb_file_name_length,edx
	mov	fb_temp_counter,esi
	test	[edx-40],byte	0x10
	jnz	.size
	dec	esi
	dec	edx
@@:
	std
	lodsb
	cmp	esi,edx
	je	.extension_size_0
	cmp	al,'.'
	jnz	@b
	add	esi,2
	mov	fb_extension_start,esi
	mov	ecx,fb_temp_counter
	sub	ecx,esi
	inc	ecx
	mov	fb_extension_size,ecx
	sub	fb_file_name_length,ecx
	cmp	ecx,2
	ja	@f
	inc	fb_file_name_length
@@:
	sub	ecx,2
	cmp	ecx,4
	jbe	@f
	mov	ecx,3
	mov	eax,fb_type_table
	mov	[eax+3],word '..'
@@:
	push	edi
	mov	edi,fb_type_table
	cld
	rep	movsb
	pop	edi
	inc	edx
	jmp	.size
.extension_size_0:
	inc	edx
	mov	fb_extension_size,0
.size:
	mov	eax,fb_type_table
	test	[edx-40],byte 0x10
	jz	.copy_size
	mov	[eax+6],dword '----'
	mov	[eax+6+4],word '- '
	jmp	.date
;-----------------------------------------
align 4
.call_decimal_string:
	mov	ebx,fb_type_table
	add	ebx,9
	call	fb_decimal_string
	mov	[ebx+1],dl
	jmp	.size_convert_end
;-----------------------------------------
.qword_div:
	mov	eax,[edx-40+32]
	mov	ebx,[edx-40+32+4]
@@:	; /1024
	shrd	eax,ebx,5 ; /32
	shr	ebx,5 ; /32
	shrd	eax,ebx,5 ; /32
	shr	ebx,5 ; /32
	dec	ecx
	jnz	@b
; /(1024*1024)
	shr	eax,20
	test	eax,eax
	ret
;-----------------------------------------
align 4
.copy_size:
;/0x1000000000000000 - EB
;/0x4000000000000 - PB
;/0x10000000000 - TB
;/0x40000000 - GB
;/0x100000 - MB
;/0x400 - KB
	mov	[eax+6],dword '    '
	mov	[eax+6+4],word '  '
	push	ebx edx
	push	ecx
	mov	ecx,4
	call	.qword_div
	pop	ecx
	jz	@f
	mov	dl,byte 'E' ; Exa Byte
	jmp	.call_decimal_string
@@:
	push	ecx
	mov	ecx,3
	call	.qword_div
	pop	ecx
	jz	@f
	mov	dl,byte 'P' ; Peta Byte
	jmp	.call_decimal_string
@@:
	push	ecx
	mov	ecx,2
	call	.qword_div
	pop	ecx
	jz	@f
	mov	dl,byte 'T' ; Tera Byte
	jmp	.call_decimal_string
@@:
	push	ecx
	mov	ecx,1
	call	.qword_div
	pop	ecx
	jz	@f
	mov	dl,byte 'G' ; Giga Byte
	jmp	.call_decimal_string
@@:
	mov	eax,[edx-40+32]
	mov	ebx,eax
	shr	eax,20 ; /(1024*1024)
	test	eax,eax
	jz	@f
	mov	dl,byte 'M' ; Mega Byte
	jmp	.call_decimal_string
@@:
	mov	eax,ebx
	shr	eax,10 ; /1024
	test	eax,eax
	jz	@f
	mov	dl,byte 'K' ; Kilo Byte
	jmp	.call_decimal_string
@@:
	mov	eax,ebx
	mov	ebx,fb_type_table
	add	ebx,10
	call	fb_decimal_string
.size_convert_end:
	pop	edx ebx
;-----------------------------------------
.date:
	cmp	[edx],word '..'
	jne	@f
	
	cmp	[edx+2],byte 0
	je	.not_show_date
@@:
	xor	eax,eax
	mov	al,[edx-40+28]
	push	ebx
	mov	ebx,fb_type_table
	add	ebx,12
	call	fb_decimal_string_2 ; day
	mov	al,[edx-40+29]
	mov	ebx,fb_type_table
	add	ebx,12+3
	call	fb_decimal_string_2 ; month
	mov	ax,[edx-40+30]
	mov	ebx,fb_type_table
	add	ebx,12+9
	mov	[ebx-3], dword '0000'
	call	fb_decimal_string ; year
	pop	ebx
;-----------------------------------------
	ror	ebx,16
	add	bx,fb_size_x
	sub	ebx,161 ; 122+12+15
	rol	ebx,16
	mov	ecx,fb_text_color
	cmp	fb_marked_file,0
	je	@f
	mov	ecx,fb_reduct_text_color
@@:
	mov	edx,fb_type_table
	mov	esi,22
	mov	ax,fb_line_size_y
	sub	ax,fb_font_size_y
	push	ebx
	mov	bx,ax
	shr	ax,1
	test	bx,1b
	jz	@f
	inc	ax
@@:
	pop	ebx
	add	bx,ax
	bts	ecx,30
	mov	eax,fb_background_color
	cmp	fb_draw_panel_selection_flag,1
	jne	@f
	mov	eax,fb_select_color
@@:
	mov	edi,eax
	mcall	SF_DRAW_TEXT
.not_show_date:
	popa
	ret
;---------------------------------------------------------------------
align 4
fb_draw_icon:
	pusha
	xor	eax,eax
	mov	ax,fb_icon_size_y
	mov	ebx,fb_resolution_raw
	imul	eax,ebx
	mov	bx,fb_icon_size_x
	imul	eax,ebx
	mov	ebx,eax
	shr	eax,3
	test	ebx,111b
	jz	@f
	inc	eax
@@:
	test	[edx-40],byte 0x10
	jnz	.draw_dir_pic
	call	fb_get_icon_number
	imul	ebx,eax	;16*16*3
	jmp	.draw
.draw_dir_pic:
	xor	ebx,ebx
	cmp	[edx],word '..'
	jne	.draw
	cmp	[edx+2],byte 0
	jne	.draw
	mov	ebx,eax	;16*16*3
.draw:
	add	ebx,fb_icon_raw_area
	mov	cx,fb_icon_size_x
	shl	ecx,16
	mov	cx,fb_icon_size_y
	mov	edx,[esp+16]
	ror	edx,16
	sub	edx,2
	sub	dx,fb_icon_size_x
	rol	edx,16
	mov	ax,fb_line_size_y
	sub	ax,fb_icon_size_y
	shr	ax,1
	add	dx,ax
	mov	esi,fb_resolution_raw
	xor	ebp,ebp
	push	edi
	mov	edi,fb_palette_raw
	mcall	SF_PUT_IMAGE_EXT
	pop	edi
	popa
	ret
;---------------------------------------------------------------------
; Convert of a binary number in decimal string form
; Input:
;  AX - value
;  EBX - address of string
; Output:
;  string contains the number, marked the end of the code 0
align 4
fb_decimal_string_2:
	push	eax ebx ecx edx
	xor	ecx,ecx
	mov	[ebx],byte '0'
	inc	ebx
.p3:
	xor	edx,edx
	push	ebx
	mov	ebx,10
	div	ebx
	pop	ebx
	add	edx,48
	push	edx
	inc	ecx
	cmp	ax,0
	jne	.p3
	cmp	ecx,1
	jbe	.p4
	mov	ecx,2
	dec	ebx
.p4:
	pop	edx
	mov	[ebx],dl
	inc	ebx
	loop	.p4
	pop	edx ecx ebx eax
	ret
;---------------------------------------------------------------------
align 4
fb_decimal_string:
	push	eax ebx ecx edx
	mov	ecx,10
;--------------------------------------
.p3:
	xor	edx,edx
	div	ecx
	add	edx,48
	mov	[ebx],dl
	dec	ebx
	test	eax,eax
	jnz	.p3

	pop	edx ecx ebx eax
	ret
;---------------------------------------------------------------------
align 4
fb_get_icon_number:
	push	eax
	mov	ebp,fb_extension_size
	test	ebp,ebp
	je	.end
	dec	ebp
	test	ebp,ebp
	je	.end
	dec	ebp
	test	ebp,ebp
	je	.end
@@:
	mov	edx,fb_ini_file_end
	sub	edx,ebp
	mov	eax,fb_ini_file_start
	dec	eax
.search_association:
	cmp	edx,eax
	jbe	.end
	inc	eax
	cmp	byte[eax], 0xa
	jne	.search_association
	inc	eax
	cmp	edx,eax
	jbe	.end
	mov	esi,fb_extension_start
	mov	ecx,eax
	mov	ebx,eax
	cld
.check:
	lodsb
	test	al,al
	jz	@f
	call	fb_char_toupper
	shl	ax,8
.search_start_of_line:
	mov	al,[ebx]
	inc	ebx
	call	fb_char_toupper
	cmp	al,ah
	je	.check
	mov	eax,ecx
	jmp	.search_association
@@:
	mov	esi,ecx
	add	esi,ebp
	lodsb
	cmp	al,byte '='
	mov	eax,ecx
	jne	.search_association
	cmp	eax,fb_ini_file_start
	je	@f
	dec	eax
	cmp	[eax],byte 15
	ja	.end
@@:
	xor	ebx,ebx
	xor	eax,eax
	mov	ecx,9
	call	.calculate
	cmp	al,0x30
	jb	.end
	cmp	al,0x39
	ja	.end
	sub	eax,0x30
@@:
	call	.calculate_1
	cmp	al,0x30
	jb	@f
	cmp	al,0x39
	ja	@f
	sub	eax,0x30
	
	lea	ebx,[ebx+ebx*4]
	shl	ebx,1
	
	dec	ecx
	jnz	@b
@@:
	pop	eax
	ret
.end:
	mov	ebx,2
	pop	eax
	ret
;---------------------------------------------------------------------
align 4
.calculate_1:
	add	ebx,eax
.calculate:
	xor	eax,eax
	cld
	lodsb
	ret
;---------------------------------------------------------------------
align 4
fb_char_toupper:
; convert character to uppercase, using cp866 encoding
; in: al=symbol
; out: al=converted symbol
	cmp	al,'a'
	jb	.ret
	cmp	al, 'z'
	jbe	.az
	cmp	al, '�'
	jb	.ret
	cmp	al, '�'
	jb	.rus1
	cmp	al, '�'
	ja	.ret
; 0xE0-0xEF -> 0x90-0x9F
	sub	al, '�'-'�'
.ret:
	ret
.rus1:
; 0xA0-0xAF -> 0x80-0x8F
.az:
	and	al, not 0x20
	ret
;---------------------------------------------------------------------
align 4
fb_char_todown:
; convert character to lowercase, using cp866 encoding
; in: al=symbol
; out: al=converted symbol
	cmp	al, 'A'
	jb	.ret
	cmp	al, 'Z'
	jbe	.az
	cmp	al, '�'
	jb	.ret
	cmp	al, '�'
	jb	.rus1
	cmp	al, '�'
	ja	.ret
; 0x90-0x9F -> 0xE0-0xEF
	add	al, '�'-'�'
.ret:
	ret
.rus1:
; 0x80-0x8F -> 0xA0-0xAF
.az:
	add	al, 0x20
	ret
;---------------------------------------------------------------------
fb_truncated_filename_char:
	db	'..'
;---------------------------------------------------------------------
;*****************************************************************************
;*****************************************************************************
; mouse event
;*****************************************************************************
;*****************************************************************************
align 4
fb_mouse:
	pusha
	mov	edi,dword [esp+36]
;-------------------------------------------------------
	mcall	SF_MOUSE_GET,SSF_BUTTON
	mov	ebx,fb_mouse_keys
	mov	fb_mouse_keys_old,ebx
	mov	fb_mouse_keys,eax
 	
	mcall	SF_MOUSE_GET,SSF_WINDOW_POSITION
	mov	ebx,fb_mouse_pos
	mov	fb_mouse_pos_old,ebx
	mov	fb_mouse_pos,eax
 	
	test	eax,0x80000000
	jnz	.exit_fb
	test	eax,0x8000
	jnz	.exit_fb

	mov	ebx,eax
	shr	ebx,16	; x position
	shl	eax,16
	shr	eax,16	; y position
 	
	mov	cx,fb_start_x
	cmp	bx,cx
	jb	.exit_fb
	
	add	cx,fb_size_x
	cmp	bx,cx
	ja	.exit_fb

	mov	cx,fb_start_y
	cmp	ax,cx
	jb	.exit_fb
	
	add	cx,fb_size_y
	cmp	ax,cx
	ja	.exit_fb

	cmp	fb_mouse_keys,0
	jz	@f
	mov	fb_select_flag,1
@@:
;------------------------------------------------------- 	
	cmp	fb_mouse_keys_delta,1
	je	.enter_1

	cmp	fb_mouse_keys,0
	jz	.exit_fb
.start:
	sub	ax,fb_start_y
	xor	ebx,ebx
	mov	bx,fb_line_size_y
	xor	edx,edx
	push	eax
	div	ebx
	pop	eax
	sub	eax,edx
	xor	edx,edx
	cmp	fb_select_panel_counter,edx
	jne	@f
	mov	fb_mouse_keys_delta,0
	jmp	.continue
@@:
	xor	edx,edx
	cmp	fb_start_draw_cursor_line,ax
	jne	@f
	cmp	fb_mouse_keys,edx
	jnz	.continue
@@:
	mov	fb_mouse_keys_delta,edx
.continue:
	xor	ebx,ebx
	mov	bx,fb_line_size_y
	imul	ebx,fb_folder_block
	cmp	eax,ebx
	jb	@f
	xor	edx,edx
	mov	dx,fb_line_size_y
	sub	ebx,edx
	cmp	bx,fb_start_draw_cursor_line
	je	.enter
	call	.store_old_cursor_line
	mov	fb_start_draw_cursor_line,bx
	jmp	.continue_1
@@:
	cmp	ax,fb_start_draw_cursor_line
	je	.enter
	call	.store_old_cursor_line
	mov	fb_start_draw_cursor_line,ax
.continue_1:
	test	fb_mouse_keys,10b
	jne	.mark_mouse
	jmp	.enter_1
.continue_2:
	mov	ax,fb_start_draw_cursor_line
	cmp	ax,fb_start_draw_cursor_line_2
	je	.exit_fb

	call	fb_draw_panel_1
	jmp	.exit_fb
.enter:
	cmp	fb_mouse_keys_delta,2
	je	.enter_2
	cmp	fb_mouse_keys_delta,1
	je	.enter_1
	mov	eax,fb_mouse_keys_old
	cmp	fb_mouse_keys,eax
	jz	.exit_fb
	test	fb_mouse_keys,10b
	jne	.mark_mouse
	xor	edx,edx
	inc	edx
	mov	fb_mouse_keys_delta,edx
	jmp	.exit_fb
.enter_1:
;	mov	eax,fb_mouse_keys_old
;	cmp	fb_mouse_keys,eax
;	jz	.exit_fb
	test	fb_mouse_keys,10b
	jne	.mark_mouse
	mov	edx,2
	mov	fb_mouse_keys_delta,edx
	mcall	SF_SYSTEM_GET,SSF_TIME_COUNT
	add	eax,fb_mouse_key_delay
	mov	fb_mouse_keys_tick,eax
	jmp	.continue_2
.enter_2:
	mcall	SF_SYSTEM_GET,SSF_TIME_COUNT
	cmp	eax,fb_mouse_keys_tick
	ja	@f
;	mov	eax,fb_mouse_pos_old
;	cmp	eax,fb_mouse_pos
;	jne	@f
	mov	eax,fb_mouse_keys_old
	cmp	fb_mouse_keys,eax
	jz	@f
	test	fb_mouse_keys,10b
	jne	.mark_mouse
	call	.enter_3
	jmp	.exit_fb
@@:
	xor	eax,eax
	inc	eax
	mov	fb_mouse_keys_delta,eax
;-------------------------------------------------------
.exit_fb:
	call	fb_prepare_selected_BDVK_adress
file_browser_exit
;-------------------------------------------------------
align 4
.mark_mouse:
	call	fb_key.mark_1
	call	fb_draw_panel_1
	xor	eax,eax
	mov	fb_mouse_keys_delta,eax
	jmp	.exit_fb	
;-------------------------------------------------------
align 4
.enter_3:
	xor	eax,eax
	mov	fb_mouse_keys,eax
	mov	fb_mouse_keys_old,eax
	mov	eax,3
	mov	fb_mouse_keys_delta,eax
	xor	eax,eax
	mov	fb_max_name_temp_size,eax
	ret
;-------------------------------------------------------
align 4
.store_old_cursor_line:
	push	eax
	mov	ax,fb_start_draw_cursor_line
	mov	fb_start_draw_cursor_line_2,ax
	xor	eax,eax
;	mov	fb_mouse_keys_delta,eax
	pop	eax
	ret
;*****************************************************************************
;*****************************************************************************
align 4
fb_prepare_selected_BDVK_adress:
	xor	eax,eax
	mov	ax,fb_start_draw_cursor_line
	xor	ebx,ebx
	mov	bx,fb_line_size_y
	xor	edx,edx
	div	ebx
	add	eax,fb_start_draw_line
	imul	eax,304
	add	eax,32
	add	eax,fb_folder_data
	mov	fb_selected_BDVK_adress,eax
	ret
;*****************************************************************************
;*****************************************************************************
; key event
; 1 - arrow down
; 2 - arrow up
; 3 - PageDown
; 4 - PageUp
; 5 - Home
; 6 - End
; 7 - Enter
; 8 - Insert (Mark)
; 9 - Mark All
; 10 - Unmark All
; 11 - Invert Mark
; 12 - Search with key
;*****************************************************************************
;*****************************************************************************
align 4
fb_key:
	pusha
	mov	edi,dword [esp+36]
;-------------------------------------------------------
	xor	eax,eax
	mov	ax,fb_key_action
	shl	eax,2
	add	eax,dword fb_key_table
	cmp	eax,fb_key_table.end
	jae	.exit_fb
	cmp	[eax],dword 0
	je	.exit_fb
	jmp	dword [eax]
;-------------------------------------------------------
align 4
.arrow_down:
	mov	ax,fb_start_draw_cursor_line
	add	ax,fb_line_size_y
	add	ax,fb_line_size_y
	cmp	ax,word fb_size_y
	ja	@f
.add_1:
	call	fb_mouse.store_old_cursor_line
	mov	ax,fb_start_draw_cursor_line
	add	ax,fb_line_size_y
	mov	fb_start_draw_cursor_line,ax
	call	fb_draw_panel_1
	jmp	.exit_fb
@@:
	mov	eax,fb_folder_block
	sub	eax,fb_max_panel_line
	test	eax,0x80000000
	jnz	.page_down_2

	call	.prepare_data_down
	ja	@f

	cmp	fb_start_draw_line,eax
	je	.exit_fb
@@:
	inc	fb_start_draw_line
	call	fb_draw_panel_3
	jmp	.exit_fb
;-------------------------------------------------------
align 4
.arrow_up:
	mov	ax,fb_start_draw_cursor_line
	add	ax,fb_start_y
	cmp	fb_start_y,ax
	je	@f
	call	fb_mouse.store_old_cursor_line
	mov	ax,fb_start_draw_cursor_line
	sub	ax,fb_line_size_y
	mov	fb_start_draw_cursor_line,ax
	call	fb_draw_panel_1
	jmp	.exit_fb
@@:
	cmp	fb_start_draw_line,0
	je	.exit_fb
	dec	fb_start_draw_line
	call	fb_draw_panel_3
	jmp	.exit_fb
;-------------------------------------------------------
align 4
.page_down:
	mov	eax,fb_max_panel_line
	mov	ebx,fb_folder_block
	sub	ebx,eax
	test	ebx,0x80000000
	jnz	.page_down_2
	sub	ebx,fb_start_draw_line
	cmp	ebx,eax
	ja	.page_down_3
	mov	ebx,fb_folder_block
	sub	ebx,eax
	call	.prepare_data_down
	ja	@f
	cmp	ebx,fb_start_draw_line
	je	.exit_fb
@@:
	mov	fb_start_draw_line,ebx
.page_down_0:
	dec	eax
	xor	ebx,ebx
	mov	bx,fb_line_size_y
	imul	eax,ebx
.page_down_1:
	call	fb_mouse.store_old_cursor_line
	mov	fb_start_draw_cursor_line,ax
	call	fb_draw_panel_2
	jmp	.exit_fb
.page_down_2:
	mov	eax,fb_folder_block
	sub	eax,fb_start_draw_line
	dec	eax
	xor	ebx,ebx
	mov	bx,fb_line_size_y
	imul	eax,ebx
	cmp	ax,fb_start_draw_cursor_line
	jbe	.exit_fb
	jmp	.page_down_1
.page_down_3:
	add	fb_start_draw_line,eax
	call	fb_draw_panel_2
	jmp	.exit_fb
;-------------------------------------------------------
align 4
.prepare_data_down:
	mov	ecx,fb_folder_block
	sub	ecx,fb_start_draw_line
	dec	ecx
	xor	edx,edx
	mov	dx,fb_line_size_y
	imul	ecx,edx
	cmp	cx,fb_start_draw_cursor_line
	ret
;-------------------------------------------------------
align 4
.page_up:
	mov	eax,fb_max_panel_line
	mov	ebx,fb_start_draw_line
	sub	ebx,eax
	test	ebx,0x80000000
	jz	@f
	cmp	fb_start_draw_line,0
	jne	.page_up_1
	cmp	fb_start_draw_cursor_line,0
	je	.exit_fb
	mov	fb_start_draw_cursor_line,0
.page_up_1:
	mov	fb_start_draw_line,0
	call	fb_draw_panel_2
	jmp	.exit_fb
@@:
	sub	fb_start_draw_line,eax
	call	fb_draw_panel_2
	jmp	.exit_fb
;-------------------------------------------------------
align 4
.home:
	cmp	fb_start_draw_line,0
	jne	@f
	cmp	fb_start_draw_cursor_line,0
	je	.exit_fb
@@:
	mov	fb_start_draw_line,0
	mov	fb_start_draw_cursor_line,0
	call	fb_mouse.store_old_cursor_line
	call	fb_draw_panel_2
	jmp	.exit_fb
;-------------------------------------------------------
align 4
.end:
	mov	eax,fb_folder_block
	sub	eax,fb_max_panel_line
	test	eax,0x80000000
	jnz	.page_down_2
	call	.prepare_data_down
	ja	@f
	cmp	eax,fb_start_draw_line
	je	.exit_fb
@@:
	mov	fb_start_draw_line,eax
	mov	eax,fb_max_panel_line
	jmp	.page_down_0
;-------------------------------------------------------
align 4
.enter:
	call	fb_mouse.enter_3
	jmp	.exit_fb
;-------------------------------------------------------
align 4
.mark:
	call	.mark_1
	jmp	.arrow_down	
;-------------------------------------------------------
align 4
.mark_1:
	mov	eax,fb_folder_block
	test	eax,eax
	jz	.exit

	xor	eax,eax
	mov	ax,fb_start_draw_cursor_line
	xor	edx,edx
	xor	ebx,ebx
	mov	bx,fb_line_size_y
	div	ebx
	mov	esi,fb_start_draw_line
	add	esi,eax
	imul	esi,304
	add	esi,fb_folder_data

	add	esi,32+299
	mov	al,[esi]
	and	al,1
	
	test	al,al
	jnz	@f
	inc	fb_marked_counter
	jmp	.mark_2
@@:
	dec	fb_marked_counter
.mark_2:
	mov	al,[esi]
	inc	al
	and	al,1
	mov	[esi],al
.exit:
	ret
;-------------------------------------------------------
align 4
.mark_all:
	mov	eax,fb_folder_block
	test	eax,eax
	jz	.exit_fb

	mov	fb_temp_counter,0
.mark_all_1:	
	mov	ebp,fb_folder_block
.mark_all_2:
	mov	ebx,ebp
	dec	ebx
	imul	ebx,304
	add	ebx,fb_folder_data
	add	ebx,32+40
	cmp	[ebx],word '..'
	jne	.mark_all_3
	cmp	[ebx+2],byte 0
	je	@f
.mark_all_3:
	call	.select_mark_action
@@:
	dec	ebp
	jnz	.mark_all_2
	
	call	fb_draw_panel_3
	cmp	fb_temp_counter,0
	jne	@f
	mov	eax,fb_folder_block
	jmp	.mark_all_4
@@:
	cmp	fb_temp_counter,1
	jne	@f
	mov	fb_marked_counter,0
	jmp	.exit_fb
@@:
	mov	eax,fb_folder_block
	sub	eax,fb_marked_counter
.mark_all_4:
	dec	eax
	mov	fb_marked_counter,eax
	jmp	.exit_fb
;-------------------------------------------------------	
align 4
.select_mark_action:
	add	ebx,299-40
	cmp	fb_temp_counter,0
	jne	@f
	mov	[ebx],byte 1
	jmp	.select_mark_action_1
@@:
	cmp	fb_temp_counter,1
	jne	@f
	mov	[ebx],byte 0
	jmp	.select_mark_action_1
@@:
	mov	al,[ebx]
	inc	al
	and	al,1
	mov	[ebx],al
.select_mark_action_1:
	ret
;-------------------------------------------------------
align 4
.unmark_all:
	mov	eax,fb_folder_block
	test	eax,eax
	jz	.exit_fb

	mov	fb_temp_counter,1
	jmp	.mark_all_1
;-------------------------------------------------------
align 4
.invert_mark:
	mov	eax,fb_folder_block
	test	eax,eax
	jz	.exit_fb

	mov	fb_temp_counter,2
	jmp	.mark_all_1
;-------------------------------------------------------
;  * bit 0  (mask 1): left Shift is pressed
;  * bit 1  (mask 2): right Shift is pressed
;  * bit 2  (mask 4): left Ctrl is pressed
;  * bit 3  (mask 8): right Ctrl is pressed
;  * bit 4  (mask 0x10): left Alt is pressed
;  * bit 5  (mask 0x20): right Alt is pressed
;  * bit 6  (mask 0x40): CapsLock is on
;  * bit 7  (mask 0x80): NumLock is on
;  * bit 8  (mask 0x100): ScrollLock is on
;  * bit 9  (mask 0x200): left Win is pressed
;  * bit 10 (mask 0x400): right Win is pressed
;-------------------------------------------------------
align 4
.search_with_key:
	mcall	SF_BOARD,SSF_GET_CONTROL_KEYS
	test	al,11b
	jnz	.shift_layout

	test	al,110000b
	jnz	.alt_layout

	mov	ecx,1	; Normal
	jmp	.get_keyboard_layout

.shift_layout:
	mov	ecx,2	; Shift
	jmp	.get_keyboard_layout

.alt_layout:
	mov	ecx,3	; Alt
.get_keyboard_layout:
	mcall	SF_SYSTEM_GET,SSF_KEYBOARD_LAYOUT,,fb_keymap_pointer
	xor	eax,eax
	mov	ax,fb_key_action_num
	add	eax,fb_keymap_pointer
	mov	al,[eax]
	and	eax,0xff
	call	fb_char_todown
	mov	ah,al
	xor	esi,esi
	push	eax
	movzx	eax,fb_start_draw_cursor_line
	movzx	ebx,fb_line_size_y
	xor	edx,edx
	div	ebx
	add	si,ax	;fb_start_draw_cursor_line
	pop	eax
	add	esi,fb_start_draw_line
	mov	ecx,esi
	xor	ebx,ebx
	inc	ecx
	cmp	ecx,fb_folder_block
	ja	.reset_data

.first_entry:
	imul	esi,304
	add	esi,fb_folder_data
	add	esi,40+32
@@:
	add	esi,304
	mov	al,[esi]
	call	fb_char_todown
	cmp	ah,al
	je	.match

	inc	ecx
	cmp	ecx,fb_folder_block
	jb	@b

.reset_data:
	xor	esi,esi
	
	dec	esi
	cmp	ebx,2
	jae	.exit_fb

	xor	ecx,ecx
	inc	ebx
	jmp	.first_entry

.match:
	mov	fb_start_draw_line,ecx
	mov	eax,fb_folder_block
	mov	ebx,fb_max_panel_line
	sub	eax,ebx
	jbe	.1

	cmp	eax,ecx
	jbe	@f
	
	xor	ecx,ecx
	jmp	.2
@@:
	mov	fb_start_draw_line,eax
	mov	eax,fb_folder_block
	sub	eax,ecx

	mov	ecx,fb_max_panel_line
	sub	ecx,eax
	jmp	.2

.1:
	xor	eax,eax
	mov	fb_start_draw_line,eax
.2:
	movzx	eax,fb_line_size_y
	imul	ecx,eax
	mov	fb_start_draw_cursor_line,cx
	call	fb_draw_panel_2
;-------------------------------------------------------
.exit_fb:
	call	fb_prepare_selected_BDVK_adress
file_browser_exit
;-------------------------------------------------------
align 4
fb_key_table:
	dd	0
	dd	fb_key.arrow_down	; 1
	dd	fb_key.arrow_up		; 2
	dd	fb_key.page_down	; 3
	dd	fb_key.page_up		; 4
	dd	fb_key.home		; 5
	dd	fb_key.end		; 6
	dd	fb_key.enter		; 7
	dd	fb_key.mark		; 8
	dd	fb_key.mark_all		; 9
	dd	fb_key.unmark_all	; 10
	dd	fb_key.invert_mark	; 11
	dd	fb_key.search_with_key	; 12
.end:
	dd	0
;-------------------------------------------------------
align 4
fb_draw_panel_3:
	mov	eax,2
	mov	fb_all_redraw,eax
	jmp	fb_draw_panel_2.1
align 4
fb_draw_panel_2:
	xor	eax,eax
	inc	eax
	mov	fb_all_redraw,eax
	call	fb_draw_panel_selection
.1:
	call	fb_draw_folder_data
	xor	eax,eax
	mov	fb_all_redraw,eax
	inc	eax
	mov	fb_draw_scroll_bar,eax
	ret

