use32
	org 0
	db 'MENUET01'
	dd 1,start,i_end,mem,stacktop,0,cur_dir_path

include '../../../../../proc32.inc'
include '../../../../../macros.inc'
include '../../../../../KOSfuncs.inc'
include '../../../../../load_img.inc'
include '../../../../../load_lib.mac'
include '../opengl_const.inc'
include '../zbuffer.inc'
include '../../../../../develop/info3ds/info_fun_float.inc'

@use_library mem.Alloc,mem.Free,mem.ReAlloc,dll.Load

IMAGE_TOOLBAR_ICON_SIZE equ 21*21*3

;Макрос для параметров типа double (8 байт)
macro glpush GLDoubleVar {
	push dword[GLDoubleVar+4]
	push dword[GLDoubleVar]
}

align 4
start:
load_libraries l_libs_start,l_libs_end
	;проверка на сколько удачно загузились библиотеки
	mov	ebp,lib_0
	.test_lib_open:
	cmp	dword [ebp+ll_struc_size-4],0
	jz	@f
		mcall SF_TERMINATE_PROCESS
	@@:
	add ebp,ll_struc_size
	cmp ebp,l_libs_end
	jl .test_lib_open

	mcall SF_STYLE_SETTINGS,SSF_GET_COLORS,sc,sizeof.system_colors
	mcall SF_SET_EVENTS_MASK,0x27

	stdcall [kosglMakeCurrent], 5,30,[buf_ogl.w],[buf_ogl.h],ctx1
	stdcall [glEnable], GL_DEPTH_TEST
	stdcall [glEnable], GL_NORMALIZE ;делам нормали одинаковой величины во избежание артефактов
	call [gluNewQuadric]
	mov [qObj],eax

	stdcall [glClearColor], 0.25,0.25,0.25,0.0
	stdcall [glShadeModel], GL_SMOOTH

	mov eax,dword[ctx1] ;eax -> TinyGLContext.GLContext
	mov eax,[eax] ;eax -> ZBuffer
	mov eax,[eax+ZBuffer.pbuf]
	mov dword[buf_ogl],eax

	load_image_file 'font8x9.bmp', image_data_toolbar, buf_1.w,buf_1.h
	stdcall [buf2d_create_f_img], buf_1,[image_data_toolbar] ;создаем буфер
	stdcall mem.Free,[image_data_toolbar] ;освобождаем память
	stdcall [buf2d_conv_24_to_8], buf_1,1 ;делаем буфер прозрачности 8 бит
	stdcall [buf2d_convert_text_matrix], buf_1

	load_image_file 'toolb_1.png', image_data_toolbar
	call SetLight
	call draw_3d

align 4
red_win:
	call draw_window

align 4
still:
	mcall SF_WAIT_EVENT
	cmp   al,EV_REDRAW
	jz    red_win
	cmp   al,EV_KEY
	jz    key
	cmp   al,EV_BUTTON
	jz    button
	jmp   still

align 4
draw_window:
	pushad
	mcall SF_REDRAW,SSF_BEGIN_DRAW
	mcall SF_CREATE_WINDOW,(50 shl 16)+420,(30 shl 16)+410,0x33ffffff,,caption

	mov esi,[sc.work_button]
	mcall SF_DEFINE_BUTTON,(6 shl 16)+19,(6 shl 16)+19,3+0x40000000 ;вершины вкл.
	mcall ,(36 shl 16)+19,,4+0x40000000 ;каркасные грани вкл.
	mcall ,(66 shl 16)+19,,5+0x40000000 ;сплошные грани вкл.
	mcall ,(96 shl 16)+19,,6+0x40000000 ;масштаб +
	mcall ,(126 shl 16)+19,,7+0x40000000 ;масштаб -

	mcall SF_PUT_IMAGE,[image_data_toolbar],(21 shl 16)+21,(5 shl 16)+5 ;вершины вкл.
	add ebx,IMAGE_TOOLBAR_ICON_SIZE
	mcall ,,,(35 shl 16)+5 ;каркасные грани вкл.
	add ebx,IMAGE_TOOLBAR_ICON_SIZE
	mcall ,,,(65 shl 16)+5 ;сплошные грани вкл.
	add ebx,IMAGE_TOOLBAR_ICON_SIZE
	mcall ,,,(95 shl 16)+5 ;масштаб +
	add ebx,IMAGE_TOOLBAR_ICON_SIZE
	mcall ,,,(125 shl 16)+5 ;масштаб -

	call [kosglSwapBuffers]
	mcall SF_REDRAW,SSF_END_DRAW
	popad
	ret

align 4
key:
	mcall SF_GET_KEY

	cmp ah,27 ;Esc
	je button.exit

	cmp ah,61 ;+
	jne @f
		call but_zoom_p
		jmp still
	@@:
	cmp ah,45 ;-
	jne @f
		call but_zoom_m
		jmp still
	@@:
	cmp ah,178 ;Up
	jne @f
		finit
		fld dword[angle_y]
		fadd dword[delt_size]
		fst dword[angle_y]
		mov word[NumberSymbolsAD],2
		fstp qword[Data_Double]
		call DoubleFloat_to_String
		mov byte[txt_angle_y.v],0
		stdcall str_cat, txt_angle_y.v,Data_String
		call draw_3d
		call [kosglSwapBuffers]
		jmp still
	@@:
	cmp ah,177 ;Down
	jne @f
		finit
		fld dword[angle_y]
		fsub dword[delt_size]
		fst dword[angle_y]
		mov word[NumberSymbolsAD],2
		fstp qword[Data_Double]
		call DoubleFloat_to_String
		mov byte[txt_angle_y.v],0
		stdcall str_cat, txt_angle_y.v,Data_String
		call draw_3d
		call [kosglSwapBuffers]
		jmp still
	@@:
	cmp ah,176 ;Left
	jne @f
		finit
		fld dword[angle_z]
		fadd dword[delt_size]
		fst dword[angle_z]
		mov word[NumberSymbolsAD],2
		fstp qword[Data_Double]
		call DoubleFloat_to_String
		mov byte[txt_angle_z.v],0
		stdcall str_cat, txt_angle_z.v,Data_String
		call draw_3d
		call [kosglSwapBuffers]
		jmp still
	@@:
	cmp ah,179 ;Right
	jne @f
		finit
		fld dword[angle_z]
		fsub dword[delt_size]
		fst dword[angle_z]
		mov word[NumberSymbolsAD],2
		fstp qword[Data_Double]
		call DoubleFloat_to_String
		mov byte[txt_angle_z.v],0
		stdcall str_cat, txt_angle_z.v,Data_String
		call draw_3d
		call [kosglSwapBuffers]
		;jmp still
	@@:

	jmp still

align 4
button:
	mcall SF_GET_BUTTON
	cmp ah,3
	jne @f
		call but_st_point
		jmp still
	@@:
	cmp ah,4
	jne @f
		call but_st_line
		jmp still
	@@:
	cmp ah,5
	jne @f
		call but_st_face
		jmp still
	@@:
	cmp ah,6
	jne @f
		call but_zoom_p
		jmp still
	@@:
	cmp ah,7
	jne @f
		call but_zoom_m
		jmp still
	@@:
	cmp ah,1
	jne still
.exit:
	stdcall [gluDeleteQuadric], [qObj]
	stdcall mem.Free,[image_data_toolbar]
	mcall SF_TERMINATE_PROCESS

align 4
but_st_point:
	stdcall [gluQuadricDrawStyle], [qObj],GLU_POINT
	call draw_3d
	call [kosglSwapBuffers]
	ret

align 4
but_st_line:
	stdcall [gluQuadricDrawStyle], [qObj],GLU_LINE
	call draw_3d
	call [kosglSwapBuffers]
	ret

align 4
but_st_face:
	stdcall [gluQuadricDrawStyle], [qObj],GLU_FILL
	call draw_3d
	call [kosglSwapBuffers]
	ret

align 4
but_zoom_p:
	finit
	fld dword[scale]
	fadd dword[sc_delt]
	fcom dword[sc_max]
	fstsw ax
	sahf
	jbe @f
		ffree st0
		fincstp
		fld dword[sc_max]
	@@:
	fst dword[scale]
	mov word[NumberSymbolsAD],3
	fstp qword[Data_Double]
	call DoubleFloat_to_String
	mov byte[txt_scale.v],0
	stdcall str_cat, txt_scale.v,Data_String
	call draw_3d
	call [kosglSwapBuffers]
	ret

align 4
but_zoom_m:
	finit
	fld dword[scale]
	fsub dword[sc_delt]
	fcom dword[sc_min]
	fstsw ax
	sahf
	ja @f
		ffree st0
		fincstp
		fld dword[sc_min]
	@@:
	fst dword[scale]
	mov word[NumberSymbolsAD],3
	fstp qword[Data_Double]
	call DoubleFloat_to_String
	mov byte[txt_scale.v],0
	stdcall str_cat, txt_scale.v,Data_String
	call draw_3d
	call [kosglSwapBuffers]
	ret


align 4
caption db 'Test gluSphere, [Esc] - exit, [<-],[->],[Up],[Down] - rotate',0

align 4
draw_3d:
stdcall [glClear], GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT ;очистим буфер цвета и глубины

call [glPushMatrix]
	stdcall [glScalef], [scale], [scale], [scale]

	stdcall [glColor3f], 1.0, 1.0, 0.0
	stdcall [glRotatef], [angle_z],0.0,0.0,1.0
	stdcall [glRotatef], [angle_y],0.0,1.0,0.0
	stdcall [gluSphere], [qObj], 1.0, 32,32

	stdcall [glColor3f], 1.0, 0.0, 0.0
	stdcall [glTranslatef], -1.6,0.0,0.0
	stdcall [gluSphere], [qObj], 0.55, 16,16

	stdcall [glColor3f], 0.0, 0.0, 1.0
	stdcall [glTranslatef], 3.2,0.0,0.0
	stdcall [gluSphere], [qObj], 0.55, 16,16
call [glPopMatrix]

	stdcall [buf2d_draw_text], buf_ogl, buf_1,txt_scale,5,5,0xffff00
	stdcall [buf2d_draw_text], buf_ogl, buf_1,txt_angle_z,5,15,0xffff00
	stdcall [buf2d_draw_text], buf_ogl, buf_1,txt_angle_y,5,25,0xffff00
	ret

align 4
SetLight:
	stdcall [glLightfv], GL_LIGHT0, GL_POSITION, light_position
	stdcall [glLightfv], GL_LIGHT0, GL_SPOT_DIRECTION, light_dir

	stdcall [glLightfv], GL_LIGHT0, GL_DIFFUSE, white_light
	stdcall [glLightfv], GL_LIGHT0, GL_SPECULAR, white_light

	stdcall [glEnable], GL_COLOR_MATERIAL
	stdcall [glColorMaterial], GL_FRONT, GL_AMBIENT_AND_DIFFUSE
	stdcall [glMaterialfv], GL_FRONT, GL_SPECULAR, mat_specular
	stdcall [glMaterialf], GL_FRONT, GL_SHININESS, mat_shininess
	stdcall [glLightModelfv], GL_LIGHT_MODEL_AMBIENT, lmodel_ambient

	stdcall [glEnable],GL_LIGHTING
	stdcall [glEnable],GL_LIGHT0
ret

scale dd 0.4 ;начальный масштаб
sc_delt dd 0.05 ;изменение масштаба при нажатии
sc_min dd 0.1 ;минимальный масштаб
sc_max dd 1.1 ;максимальный масштаб
angle_z dd 0.0
angle_y dd 0.0
delt_size dd 3.0

light_position dd 3.0, 2.0, -10.0, 1.0 ; Расположение источника [0][1][2]
	;[3] = (0.0 - бесконечно удаленный источник, 1.0 - источник света на определенном расстоянии)
light_dir dd 0.0,0.0,0.0 ;направление лампы
mat_specular dd 0.1, 0.1, 0.1, 1.0 ; Цвет блика
mat_shininess dd 3.0 ; Размер блика (обратная пропорция)
white_light dd 0.8, 0.8, 0.8, 1.0 ; Цвет и интенсивность освещения, генерируемого источником
lmodel_ambient dd 0.2, 0.2, 0.2, 1.0 ; Параметры фонового освещения

;--------------------------------------------------
align 4
import_tinygl:

macro E_LIB n
{
	n dd sz_#n
}
include '../export.inc'
	dd 0,0
macro E_LIB n
{
	sz_#n db `n,0
}
include '../export.inc'

align 4
import_buf2d:
	dd sz_init0
	buf2d_create dd sz_buf2d_create
	buf2d_create_f_img dd sz_buf2d_create_f_img
	buf2d_clear dd sz_buf2d_clear
	buf2d_draw dd sz_buf2d_draw
	buf2d_delete dd sz_buf2d_delete
	buf2d_resize dd sz_buf2d_resize
	buf2d_line dd sz_buf2d_line
	buf2d_rect_by_size dd sz_buf2d_rect_by_size
	buf2d_filled_rect_by_size dd sz_buf2d_filled_rect_by_size
	buf2d_circle dd sz_buf2d_circle
	buf2d_img_hdiv2 dd sz_buf2d_img_hdiv2
	buf2d_img_wdiv2 dd sz_buf2d_img_wdiv2
	buf2d_conv_24_to_8 dd sz_buf2d_conv_24_to_8
	buf2d_conv_24_to_32 dd sz_buf2d_conv_24_to_32
	buf2d_bit_blt dd sz_buf2d_bit_blt
	buf2d_bit_blt_transp dd sz_buf2d_bit_blt_transp
	buf2d_bit_blt_alpha dd sz_buf2d_bit_blt_alpha
	buf2d_curve_bezier dd sz_buf2d_curve_bezier
	buf2d_convert_text_matrix dd sz_buf2d_convert_text_matrix
	buf2d_draw_text dd sz_buf2d_draw_text
	buf2d_crop_color dd sz_buf2d_crop_color
	buf2d_offset_h dd sz_buf2d_offset_h
	buf2d_flood_fill dd sz_buf2d_flood_fill
	buf2d_set_pixel dd sz_buf2d_set_pixel
	dd 0,0
	sz_init0 db 'lib_init',0
	sz_buf2d_create db 'buf2d_create',0
	sz_buf2d_create_f_img db 'buf2d_create_f_img',0
	sz_buf2d_clear db 'buf2d_clear',0
	sz_buf2d_draw db 'buf2d_draw',0
	sz_buf2d_delete db 'buf2d_delete',0
	sz_buf2d_resize db 'buf2d_resize',0
	sz_buf2d_line db 'buf2d_line',0
	sz_buf2d_rect_by_size db 'buf2d_rect_by_size',0
	sz_buf2d_filled_rect_by_size db 'buf2d_filled_rect_by_size',0
	sz_buf2d_circle db 'buf2d_circle',0
	sz_buf2d_img_hdiv2 db 'buf2d_img_hdiv2',0
	sz_buf2d_img_wdiv2 db 'buf2d_img_wdiv2',0
	sz_buf2d_conv_24_to_8 db 'buf2d_conv_24_to_8',0
	sz_buf2d_conv_24_to_32 db 'buf2d_conv_24_to_32',0
	sz_buf2d_bit_blt db 'buf2d_bit_blt',0
	sz_buf2d_bit_blt_transp db 'buf2d_bit_blt_transp',0
	sz_buf2d_bit_blt_alpha db 'buf2d_bit_blt_alpha',0
	sz_buf2d_curve_bezier db 'buf2d_curve_bezier',0
	sz_buf2d_convert_text_matrix db 'buf2d_convert_text_matrix',0
	sz_buf2d_draw_text db 'buf2d_draw_text',0
	sz_buf2d_crop_color db 'buf2d_crop_color',0
	sz_buf2d_offset_h db 'buf2d_offset_h',0
	sz_buf2d_flood_fill db 'buf2d_flood_fill',0
	sz_buf2d_set_pixel db 'buf2d_set_pixel',0

align 4
import_libimg:
	dd alib_init1
;	img_is_img  dd aimg_is_img
;	img_info    dd aimg_info
;	img_from_file dd aimg_from_file
;	img_to_file dd aimg_to_file
;	img_from_rgb dd aimg_from_rgb
;	img_to_rgb  dd aimg_to_rgb
	img_to_rgb2 dd aimg_to_rgb2
	img_decode  dd aimg_decode
;	img_encode  dd aimg_encode
;	img_create  dd aimg_create
	img_destroy dd aimg_destroy
;	img_destroy_layer dd aimg_destroy_layer
;	img_count   dd aimg_count
;	img_lock_bits dd aimg_lock_bits
;	img_unlock_bits dd aimg_unlock_bits
;	img_flip    dd aimg_flip
;	img_flip_layer dd aimg_flip_layer
;	img_rotate  dd aimg_rotate
;	img_rotate_layer dd aimg_rotate_layer
;	img_draw    dd aimg_draw
;	img_convert dd aimg_convert

	dd 0,0
	alib_init1   db 'lib_init',0
;	aimg_is_img  db 'img_is_img',0 ;определяет по данным, может ли библиотека сделать из них изображение
;	aimg_info    db 'img_info',0
;	aimg_from_file db 'img_from_file',0
;	aimg_to_file db 'img_to_file',0
;	aimg_from_rgb db 'img_from_rgb',0
;	aimg_to_rgb  db 'img_to_rgb',0 ;преобразование изображения в данные RGB
	aimg_to_rgb2 db 'img_to_rgb2',0
	aimg_decode  db 'img_decode',0 ;автоматически определяет формат графических данных
;	aimg_encode  db 'img_encode',0
;	aimg_create  db 'img_create',0
	aimg_destroy db 'img_destroy',0
;	aimg_destroy_layer db 'img_destroy_layer',0
;	aimg_count   db 'img_count',0
;	aimg_lock_bits db 'img_lock_bits',0
;	aimg_unlock_bits db 'img_unlock_bits',0
;	aimg_flip    db 'img_flip',0
;	aimg_flip_layer db 'img_flip_layer',0
;	aimg_rotate  db 'img_rotate',0
;	aimg_rotate_layer db 'img_rotate_layer',0
;	aimg_draw    db 'img_draw',0
;	aimg_convert db 'img_convert',0

;--------------------------------------------------
system_dir_0 db '/sys/lib/'
lib_name_0 db 'tinygl.obj',0
system_dir_1 db '/sys/lib/'
lib_name_1 db 'buf2d.obj',0
system_dir_2 db '/sys/lib/'
lib_name_2 db 'libimg.obj',0
;--------------------------------------------------

txt_scale:
db 'Scale: '
.v:
db 0
rb 10

txt_angle_z:
db 'Rotate z: '
.v:
db 0
rb 10

txt_angle_y:
db 'Rotate y: '
.v:
db 0
rb 10

align 4
buf_ogl:
	dd 0 ;указатель на буфер изображения
	dw 10,10 ;+4 left,top
.w: dd 400
.h: dd 350
	dd 0,24 ;+16 color,bit in pixel

align 4
buf_1:
	dd 0 ;указатель на буфер изображения
	dd 0 ;+4 left,top
.w: dd 0
.h: dd 0,0,24 ;+16 color,bit in pixel

align 4
l_libs_start:
	lib_0 l_libs lib_name_0, file_name, system_dir_0, import_tinygl
	lib_1 l_libs lib_name_1, file_name, system_dir_1, import_buf2d
	lib_2 l_libs lib_name_2, file_name, system_dir_2, import_libimg
l_libs_end:

align 4
i_end:
	ctx1 rb 28 ;sizeof.TinyGLContext = 28
	image_data_toolbar dd 0
	qObj dd 0
	run_file_70 FileInfoBlock
	sc system_colors
align 16
	cur_dir_path rb 4096
	file_name rb 4096
	rb 4096
stacktop:
mem:
