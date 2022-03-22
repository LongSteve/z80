;
; This is a modified version of the Trinity BootLoader code, created by Colin Piggot (@QuazarSamCoupe) (www.samcoupe.com)
; and published in Issue 23 of SAM Revival magazine.  It's almost all the same, except for the addition of the bits that
; display the strips after BDOS has loaded.
;

; 1K Boot Block to load
; in B-DOS 1.5t beta
    ORG     16384
    DUMP    16384

;
; Defines					
;
PALTAB:				EQU		&55D8
LINICOLS:			EQU		&5600
JREADKEY:           EQU     &0169
JCLSBL:         	EQU     &014E
BGFLG:              EQU     &5A34
THFATP:             EQU     &5A44

start:
; save LMPR / HMPR
    IN      A,(250)
    LD      (restore+1),A
    OR      64
    OUT     (250),A
    IN      A,(251)
    LD      (restore2+1),A
    LD      A,29
    OUT     (251),A
    DI

; load in bdos chunks 2-13
    LD      A,2
    LD      (value),A
    LD      HL,32768
    CALL    read_chunk

    LD      A,3
    LD      (value),A
    LD      HL,32768+1024
    CALL    read_chunk

    LD      A,4
    LD      (value),A
    LD      HL,32768+2048
    CALL    read_chunk

    LD      A,5
    LD      (value),A
    LD      HL,32768+3072
    CALL    read_chunk

    LD      A,6
    LD      (value),A
    LD      HL,32768+4096
    CALL    read_chunk

    LD      A,7
    LD      (value),A
    LD      HL,32768+5120
    CALL    read_chunk

    LD      A,8
    LD      (value),A
    LD      HL,32768+6144
    CALL    read_chunk

    LD      A,9
    LD      (value),A
    LD      HL,32768+7168
    CALL    read_chunk

    LD      A,10
    LD      (value),A
    LD      HL,32768+8192
    CALL    read_chunk

    LD      A,11
    LD      (value),A
    LD      HL,32768+9216
    CALL    read_chunk

    LD      A,12
    LD      (value),A
    LD      HL,32768+10240
    CALL    read_chunk

    LD      A,13
    LD      (value),A
    LD      HL,32768+11264
    CALL    read_chunk

; execute the DOS
    CALL    32876

; show the old school strips
    CALL    stripes

; TODO: Use a trinity flash ram variable to determine if we should look for an auto* file
; on a specific record, and attempt to load and run it

; restore LMPR / HMPR
restore:
    LD      A,0
    OUT     (250),A
restore2:
    LD      A,0
    OUT     (251),A
    JP      4143    ; ERRHAND2 (exit to basic)

value:
    DEFB    0

read_chunk:
    LD      (c_addr+1),HL
    
    LD      A,(value)
    CALL    get_chunk
    CALL    eeprom_enable

    LD      BC,&00DD
    LD      DE,&0400

    LD      A,&03
    OUT     (C),A
    CALL    wait_ready
    OUT     (C),H
    CALL    wait_ready
    OUT     (C),L
    CALL    wait_ready
    OUT     (C),E
    CALL    wait_ready

c_addr:
    LD      HL,0

read_cloop:
    OUT     (C),E
    CALL    wait_ready
    IN      A,(C)
    LD      (HL),A
    INC     HL

    PUSH    BC
    LD      BC,248
    AND     16
    OUT     (C),A
    POP     BC

    DEC     B
    JR      NZ,read_cloop
    DEC     D
    JR      NZ,read_cloop
    JP      exit

eeprom_enable:
    LD      A,&11
    OUT     (&DC),A
    JP      wait_ready

eeprom_disable:
    LD      A,&10
    OUT     (&DC),A
    JP      wait_ready

exit:
    CALL    eeprom_disable
    CALL    write_disable
    JP      wait_ready

wait_ready:
    IN      A,(&DC)
    AND     &08
    JR      NZ,wait_ready
    RET

get_index:
    LD      HL,-64
    LD      DE,64
    LD      B,A
get_loop:
    ADD     HL,DE
    DJNZ    get_loop
    RET

get_chunk:
    LD      HL,28
    LD      DE,4
    LD      B,A
chunk_loop:
    ADD     HL,DE
    DJNZ    chunk_loop
    RET

write_delay:
    PUSH    BC
    LD      BC,16
delay_loop:
    DJNZ    delay_loop
    DEC     C
    JR      NZ,delay_loop
    POP     BC
    RET

write_enable:
    CALL    eeprom_enable
    LD      A,&06
    OUT     (&DD),A
    CALL    wait_ready
    CALL    eeprom_disable
    RET

write_disable:
    CALL    eeprom_enable
    LD      A,&04
    OUT     (&DD),A
    CALL    wait_ready
    CALL    eeprom_disable
    RET

;
; Draw classic boot strips (code taken from original ROM)
;
stripes:            
    CALL    clearscn
    LD		DE,PALTAB+1
    LD		HL,LINICOLS
    LD		B,L
    LD		C,L
rbowl:				LD		(HL),B
    INC		HL
    LD		(HL),C
    INC		HL
    LD		A,(DE)
    INC		DE
    LD		(HL),A
    INC		HL
    LD		(HL),A
    INC		HL
    LD		A,B
    ADD		A,0x0B
    LD		B,A
    CP		0xA6
    JR		C,rbowl    
;
; Print a Text String
;
print_text:
    LD 		HL,text1		; Set pointer to start of text 
    LD 		B,53			; Set up loop counter, 20 characters to print

print_loop:
    LD 		A,(HL)			; Get character from pointer
    RST 	16				; Print character
    INC 	HL				; Move to next character
    DJNZ 	print_loop		; If we've not yet reach the last character, then loop
print_e:
    LD      HL,BGFLG
    LD      A,&82
    LD      (HL),A
    RST     16
print_text2:
    LD      HL,text2
    LD      B,5
print_loop2:
    LD      A,(HL)
    RST     16
    INC     HL
    DJNZ    print_loop2
;
; Now we wait for the User to press a key
;
wait_for_key:
    CALL	JREADKEY    	; Read the Keyboard (Zero if no key)
    JR 		Z,wait_for_key 	; If no key pressed, then loop
                            ; A key was pressed....
    LD      HL,LINICOLS     ; Clear the palette strips
    LD      (HL),&FF
    CALL    clearscn
    RET						; Return back to BASIC

;
; Clear the screen good
;
clearscn:
    LD      A,0
    LD      HL, THFATP
    LD      (HL), &00
    INC		HL
    LD      (HL), &07
    INC		HL
    LD      (HL), &00
    INC		HL
    LD      (HL), &00
    INC		HL
    LD      (HL), &00
    INC		HL
    LD      (HL), &77
    INC		HL
    LD      (HL), &00
    INC		HL
    LD      (HL), &00
    RET

;
; Text for the startup screen
;
text1:
    DM 		"   MILES GORDON TECHNOLOGY PLC       "
    DB      &7F
    DM      " 1990  SAM Coup"
text2:
    DM      " 512K"    