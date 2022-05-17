name xsvab_zadanie1_17

include zadanie1.txt

.model tiny
.stack 100h

.data
argument_stav db 0
nacitane_znaky db 0
input_size EQU 32
slovo1_stav db 0
slovo1_len dw 0
slovo1_prompt db 'Enter string that will be replaced: $'
slovo1 db input_size, 0, input_size+1 DUP('$')
slovo2_stav db 0
slovo2_len dw 0
slovo2_prompt db 'Enter substitute string: $'
slovo2 db input_size, 0, input_size+1 DUP('$')
slovo_len_dif dw 0
file_input_state db 0
file_input_prompt db 'Enter name of input file: $'
file_input db input_size, 0, input_size+1 DUP('$')
file_output_state db 0
file_output_prompt db 'Enter name of output file: $'
file_output db input_size, 0, input_size+1 DUP('$')
subor_error db 'File was not opened correctly$'
arg_error_message db 'Incorrect arguments! Type "zadanie1.exe -h" for more information.$'
help_message db 'This program reads input file and creates output file in which each instance of stringA is replaced by stringB.', 10, 'Afterwards the contents of this output file are displayed.', 10, 10, 'zadanie1 [-a stringA] [-b stringB] [-i inputFile] [-o outputFile] [-p] [-h]', 10,'[-a stringA]: string to be replaced', 10, '[-b stringB]: substitute string', 10, '[-i inputFile]: input file', 10, '[-o outputFile]: output file', 10, '[-p]: paged output', 10,  '[-h]: displays this info', '$'
display_prompt db 'Press Q to quit, E to display previous page or R to display next page.$'
cur_page dw 0
page_size dw 0
page_size_tmp dw 0
buffer_size EQU 100
buffer db buffer_size+input_size DUP('$')
buffer2 db buffer_size+input_size DUP('$')
fhandler_input dw ?
fhandler_output dw ?
nasiel_zhodu db 0
double_buffer db 0
som_v_buffer2 db 0
pocet_riadkov db 0
paging_output db 0

.code
.386

read_string PROC
    push bp
    mov bp, sp

    mov dx, [bp+4] ;mov dx, offset string_prompt
    mov ah, 9h
    int 21h

    mov dx, [bp+6] ;mov dx, offset string
    mov ah, 0ah
    int 21h

    println

    mov si, [bp+4] ;mov si, offset string+2
    najdi_carriage_return:
    inc si
    cmp byte ptr [si], 13
    jne najdi_carriage_return
    mov byte ptr [si], '$'

    mov sp, bp
    pop bp
    ret 4
read_string endp

process_args PROC
    mov al, byte ptr es:[80h]
    cmp al, 0
    je nacitaj_znak_fin_ok

    mov si, 82h
    nacitaj_znak:
    mov al, byte ptr es:[80h]
    dec al
    cmp nacitane_znaky, al
    je nacitaj_znak_fin
    mov dl, byte ptr es:[si]

    ; '' + '-'
    argument_stav_0:
    cmp argument_stav, 0
    jne argument_stav_1

    cmp dl, '-'
    jne arg_error
    mov argument_stav, 1
    jmp nacitaj_znak_pokracuj

    ; ' -' + 'a'/'b'/'i'/'o'/'p'/'h'
    argument_stav_1:
    cmp argument_stav, 1
    jne argument_stav_2

    mov argument_stav, 2
    push dx
    cmp dl, 'a'
    je nastav_argument_a
    cmp dl, 'b'
    je nastav_argument_b
    cmp dl, 'i'
    je nastav_argument_i
    cmp dl, 'o'
    je nastav_argument_o
    cmp dl, 'p'
    je nastav_argument_p
    cmp dl, 'h'
    jne arg_error
    print_help

    nastav_argument_a:
    cmp slovo1_stav, 0
    jne arg_error
    mov slovo1_stav, 1
    mov di, offset slovo1+2
    jmp nacitaj_znak_pokracuj
    nastav_argument_b:
    cmp slovo2_stav, 0
    jne arg_error
    mov slovo2_stav, 1
    mov di, offset slovo2+2
    jmp nacitaj_znak_pokracuj
    nastav_argument_i:
    cmp file_input_state, 0
    jne arg_error
    mov file_input_state, 1
    mov di, offset file_input+2
    jmp nacitaj_znak_pokracuj
    nastav_argument_o:
    cmp file_output_state, 0
    jne arg_error
    mov file_output_state, 1
    mov di, offset file_output+2
    jmp nacitaj_znak_pokracuj
    nastav_argument_p:
    pop ax
    mov argument_stav, 'p'
    cmp paging_output, 0
    jne arg_error
    mov paging_output, 1
    jmp nacitaj_znak_pokracuj

    ; ' -a'/' -b'/' -i'/' -o' + ' '
    argument_stav_2:
    cmp argument_stav, 2
    jne argument_stav_abio

    cmp dl, ' '
    jne arg_error
    pop dx
    mov argument_stav, dl
    jmp nacitaj_znak_pokracuj

    ; ' -a  '/' -b '/' -i '/' -o ' + 'arg'
    argument_stav_abio:
    cmp argument_stav, 'a'
    je argument_stav_abio_pokracuj
    cmp argument_stav, 'b'
    je argument_stav_abio_pokracuj
    cmp argument_stav, 'i'
    je argument_stav_abio_pokracuj
    cmp argument_stav, 'o'
    je argument_stav_abio_pokracuj
    jmp argument_stav_p

    argument_stav_abio_pokracuj:
    cmp dl, ' '
    je argument_stav_abio_fin
    mov [di], dl
    inc di
    jmp nacitaj_znak_pokracuj
    
    ; ' -p' + ' '
    argument_stav_p:
    cmp argument_stav, 'p'
    jne arg_error
    cmp dl, ' '
    jne arg_error
    mov argument_stav, 0
    jmp nacitaj_znak_pokracuj

    argument_stav_abio_fin:
    mov argument_stav, 0
    jmp nacitaj_znak_pokracuj

    ; nespravny vstupny argument
    arg_error:
    print_string arg_error_message
    end_program

    ; precitaj dalsi znak
    nacitaj_znak_pokracuj:
    inc si
    inc nacitane_znaky
    jne nacitaj_znak

    nacitaj_znak_fin:

    cmp argument_stav, 0
    je nacitaj_znak_fin_ok
    cmp argument_stav, 'a'
    je nacitaj_znak_fin_ok
    cmp argument_stav, 'b'
    je nacitaj_znak_fin_ok
    cmp argument_stav, 'i'
    je nacitaj_znak_fin_ok
    cmp argument_stav, 'o'
    je nacitaj_znak_fin_ok
    cmp argument_stav, 'p'
    je nacitaj_znak_fin_ok
    jmp arg_error

    nacitaj_znak_fin_ok:
    ret
process_args endp

user_input PROC
    cmp byte ptr [offset slovo1+2], '$'
    jne nenacitaj_slovo1

    nacitaj_slovo1:
    push offset slovo1
    push offset slovo1_prompt
    call read_string
    cmp byte ptr [slovo1+2], '$'
    je nacitaj_slovo1
    nenacitaj_slovo1:

    cmp byte ptr [offset slovo2+2], '$'
    jne nenacitaj_slovo2

    nacitaj_slovo2:
    push offset slovo2
    push offset slovo2_prompt
    call read_string
    cmp byte ptr [slovo2+2], '$'
    je nacitaj_slovo2
    nenacitaj_slovo2:

    cmp byte ptr [offset file_input+2], '$'
    jne nenacitaj_vstupny_subor

    nacitaj_vstupny_subor:
    push offset file_input
    push offset file_input_prompt
    call read_string
    cmp byte ptr [file_input+2], '$'
    je nacitaj_vstupny_subor
    nenacitaj_vstupny_subor:
    
    cmp byte ptr [offset file_output+2], '$'
    jne nenacitaj_vystupny_subor
    
    nacitaj_vystupny_subor:
    push offset file_output
    push offset file_output_prompt
    call read_string
    cmp byte ptr [file_output+2], '$'
    je nacitaj_vystupny_subor
    nenacitaj_vystupny_subor:

    ret
user_input endp

set_output_file PROC
    mov di, offset slovo1+2

    citaj_subor:
    clear_buffer buffer, buffer_size+1
    mov ah, 3fh
    mov bx, fhandler_input
    mov cx, buffer_size
    mov dx, offset buffer
    int 21h

    cmp ax, 0
    je koniec_suboru

    mov si, offset buffer
    dec si

    porovnaj_buffer:
    inc si
    cmp byte ptr [si], '$'
    je dalsi_buffer
    mov dl, byte ptr [di]
    cmp byte ptr [si], dl
    je znak_rovnaky
    cmp nasiel_zhodu, 1
    jne porovnaj_buffer
    pop si
    mov nasiel_zhodu, 0
    mov di, offset slovo1+2
    cmp double_buffer, 1
    jne porovnaj_buffer
    mov som_v_buffer2, 1
    jmp porovnaj_buffer
    znak_rovnaky:
    cmp nasiel_zhodu, 0
    jne nie_prvy_znak
    mov nasiel_zhodu, 1
    push si
    nie_prvy_znak:
    inc di
    cmp byte ptr [di], '$'
    jne porovnaj_buffer

    mov ax, slovo1_len
    sub ax, slovo2_len
    je posun_fin
    jg posun_dolava
    jl posun_doprava

    posun_dolava:
    mov di, si
    sub di, slovo_len_dif
    cmp double_buffer, 1
    jne posun_dolava_1
    mov ax, offset buffer
    sub ax, di
    dec ax
    jle posun_dolava_1
    mov di, offset buffer2
    add di, buffer_size
    sub di, ax
    dec di
    posun_dolava_1:
    inc si
    inc di
    cmp byte ptr [di], '$'
    jne posun_dolava_2
    mov di, offset buffer
    posun_dolava_2:
    mov dl, byte ptr [si]
    mov byte ptr [di], dl
    cmp byte ptr [si], '$'
    jne posun_dolava_1
    jmp posun_fin

    posun_doprava:
    mov cx, si
    posun_doprava_1:
    inc si
    cmp byte ptr [si], '$'
    jne posun_doprava_1
    inc si
    mov di, si
    add di, slovo_len_dif
    posun_doprava_2:
    dec si
    cmp si, cx
    je posun_fin
    dec di
    mov dl, byte ptr [si]
    mov byte ptr [di], dl
    jmp posun_doprava_2

    posun_fin:
    mov di, offset slovo2+2
    pop si
    vymen_znak:
    mov dl, byte ptr [di]
    mov byte ptr [si], dl
    inc si
    inc di
    cmp byte ptr [di], '$'
    je koniec_vymeny
    cmp double_buffer, 1
    jne vymen_znak
    cmp byte ptr [si], '$'
    jne vymen_znak

    mov double_buffer, 0
    write_to_file buffer2, fhandler_output
    mov si, offset buffer
    jmp vymen_znak

    koniec_vymeny:
    mov nasiel_zhodu, 0
    mov di, offset slovo1+2
    dec si
    cmp double_buffer, 1
    jne porovnaj_buffer
    write_to_file buffer2, fhandler_output
    mov double_buffer, 0
    jmp porovnaj_buffer

    dalsi_buffer:
    cmp nasiel_zhodu, 1
    jne vypis_buffer
    cmp double_buffer, 1
    jne vytvor_buffer2
    cmp som_v_buffer2, 1
    jne dalsi_buffer_2
    mov si, offset buffer
    dec si
    jmp porovnaj_buffer
    dalsi_buffer_2:
    write_to_file buffer2, fhandler_output
    write_to_file buffer, fhandler_output
    mov double_buffer, 0
    mov nasiel_zhodu, 0
    mov som_v_buffer2, 0
    jmp ukonc_vypis

    vytvor_buffer2:
    push di
    strcpy buffer, buffer2
    pop di
    pop ax
    sub ax, offset buffer
    add ax, offset buffer2
    push ax
    mov double_buffer, 1
    jmp citaj_subor

    vypis_buffer:
    cmp double_buffer, 1
    je vypis_buffer2
    write_to_file buffer, fhandler_output
    jmp citaj_subor

    vypis_buffer2:
    write_to_file buffer2, fhandler_output
    mov double_buffer, 0
    mov som_v_buffer2, 0
    jmp citaj_subor

    koniec_suboru:
    cmp double_buffer, 1
    jne ukonc_vypis
    mov double_buffer, 0
    mov nasiel_zhodu, 0
    write_to_file buffer2, fhandler_output
    pop ax
    ret

    ukonc_vypis:
    ret
set_output_file endp

display_output_file PROC
    ; set pointer to start of file
    mov ah, 42h
    mov al, 0
    mov bx, fhandler_output
    mov cx, 0
    mov dx, 0
    int 21h
    cmp paging_output, 1
    je dalsia_strana
    clrscr
    vypis_cely_subor:
    clear_buffer buffer, buffer_size+1
    mov ah, 3fh
    mov bx, fhandler_output
    mov cx, buffer_size
    mov dx, offset buffer
    int 21h
    cmp ax, 0
    je display_end
    print_string buffer
    jmp vypis_cely_subor
    
    predosla_strana:
    cmp cur_page, 1
    je cakaj_na_input
    dec cur_page
    
    mov ah, 42h
    mov al, 1
    mov bx, fhandler_output
    mov cx, -1
    mov dx, 0
    sub dx, page_size
    sub dx, 500
    int 21h
    jmp vypis_stranu

    dalsia_strana:
    clear_buffer buffer, buffer_size+1
    mov ah, 3fh
    mov bx, fhandler_output
    mov cx, buffer_size
    mov dx, offset buffer
    int 21h
    cmp ax, 0
    je cakaj_na_input
    clrscr
    mov pocet_riadkov, 1
    print_string buffer
    strlen buffer, page_size
    inc cur_page
    jmp vypis_riadok
    
    vypis_stranu:
    mov pocet_riadkov, 0
    mov page_size, 0
    clrscr
    vypis_riadok:
    clear_buffer buffer, buffer_size+1
    mov ah, 3fh
    mov bx, fhandler_output
    mov cx, buffer_size
    mov dx, offset buffer
    int 21h
    cmp ax, 0
    je ukonc_vypis_strany
   
    print_string buffer
    strlen buffer, page_size_tmp
    mov ax, page_size_tmp
    add page_size, ax
    inc pocet_riadkov
    cmp pocet_riadkov, 5
    jne vypis_riadok
    ukonc_vypis_strany:
    println
    println
    print_string display_prompt
    jmp cakaj_na_input

    cakaj_na_input:
    mov ah, 8
    int 21h
    
    cmp al, 'r'
    je dalsia_strana
    cmp al, 'e'
    je predosla_strana
    cmp al, 'q'
    je display_end
    jmp cakaj_na_input
    
    display_end:
    ret
display_output_file endp

Main:
    ; PRESUN PSP Z DS DO ES
    mov ax, ds
    mov es, ax

    ; NACITANIE DAT
    mov ax, @data
    mov ds, ax

    ; NACITANIE VSTUPU
    call process_args
    call user_input
    clrscr

    strlen slovo1+2, slovo1_len
    strlen slovo2+2, slovo2_len
    val_dif slovo1_len, slovo2_len, slovo_len_dif
    stringToDefault file_input+2
    stringToDefault file_output+2

    open_file file_input+2, fhandler_input
    create_file file_output+2, fhandler_output
    call set_output_file
    close_file fhandler_input
    call display_output_file
    close_file fhandler_output

    end_program
End Main