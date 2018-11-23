;*******************************************************************************
;                                                                              *
;    Filename:      Proyecto2 Brazo ---> código principal                                                              *
;    Date:	    12/17/2018                                                              
;    File Version:  V.1                                                           
;    Author:        Steven Josué Castillo Lou                                                  
;    Company:       UVG ciclo3                                                           
;    Description:   Progra para 4 PWMs                                                  *
;                                                                              *
;*******************************************************************************
#include "p16f887.inc"
; __config 0xE0F4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
;*******************************************************************************
GPR_VAR       UDATA
W_TEMP         RES      1      ; w register for context saving (ACCESS)
STATUS_TEMP    RES      1      ; status used for context saving
DELAY1	       RES	1
DELAY2	       RES	1
VALOR_ADC      RES	1
SELECTOR_SERVO RES	1
SELECTOR_ADC   RES	1
CCPRS1L	       RES	1 
CCPRS2L	       RES      1     
CCPRS3L	       RES      1      ; VARIABLES PARA LOS 4 PWMS   
CCPRS4L	       RES      1     


;*******************************************************************************
; Reset Vector
;*******************************************************************************

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

;*******************************************************************************
ISR_VECT  CODE    0x0004  
    BCF	  INTCON, INTE ;SE DESHABILITA LA INTERRUPCION DEL RB0 
PUSH:
    MOVWF W_TEMP
    SWAPF STATUS,W
    MOVWF STATUS_TEMP
ISR:
    BTFSC INTCON,INTF	;REVISA SI LA BANDERA DEL LA INTERRUPCION EXTERNA (RB0) CAMBIO DE SERVOS
    CALL  INT_SERVOS
    
POP:
    SWAPF STATUS_TEMP,W
    MOVWF STATUS
    SWAPF W_TEMP,F
    SWAPF W_TEMP,W
    BANKSEL PORTA
    BSF	    INTCON, INTE ;SE HABILITA NUEVAMENTE LA INTERRUPCION EXTERNA
    RETFIE
    
    
;-------------------------- SUBRUTINAS INTERRUPCIONES ---------------------------
INT_SERVOS
    BCF	  INTCON,INTF  
    INCF  PORTE,F
    BTFSC SELECTOR_SERVO,0
    CALL  MOVER_SERVO1
    BTFSC SELECTOR_SERVO,1
    CALL  MOVER_SERVO2
    BTFSC SELECTOR_SERVO,2
    CALL  MOVER_SERVO3
    BTFSC SELECTOR_SERVO,3
    CALL  MOVER_SERVO4
    RLF	  SELECTOR_SERVO
    BTFSS SELECTOR_SERVO,3
    GOTO  SALIR_SERVO
    CLRF  SELECTOR_SERVO
    BSF   SELECTOR_SERVO,0
    
SALIR_SERVO:
    BTFSS PORTE,2
    RETURN 
    CLRF  PORTE
    RETURN
     
MOVER_SERVO1
    MOVF  CCPRS1L,W
    MOVWF CCPR1L    ;mueve el PWM Para el 1er. motor
    RETURN 
    
MOVER_SERVO2
    MOVF  CCPRS2L,W
    MOVWF CCPR1L    ;mueve el PWM para el 2do. motor
    RETURN 
    
MOVER_SERVO3
    MOVF  CCPRS3L,W
    MOVWF CCPR1L    ;mueve el PWM para el 3er. motor
    RETURN 
    
MOVER_SERVO4
    MOVF  CCPRS4L,W
    MOVWF CCPR1L   ;mueve el PWM papra el 4to motor
    RETURN 
    

;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG CODE                      ; let linker place main program 
 
START
    CALL    CONFIG_IO 
    CALL    CONFIG_RELOJ		; RELOJ INTERNO DE 500KHz
    CALL    CONFIG_ADC			; canal 0, fosc/8, adc on, justificado a la izquierda, Vref interno (0-5V)
    CALL    CONFIG_PWM
    CALL    CONFIG_INTERRUPT
    BANKSEL PORTA  
    
INICIO
    CALL  CONV_ADC
    BTFSS ADCON0,GO
    GOTO  SALIR 
    CALL  SELECTOR_CANAL_ADC
SALIR
    GOTO  INICIO
    
SELECTOR_CANAL_ADC
   
    BTFSC SELECTOR_ADC,0
    CALL  CANAL_AN0
    BTFSC SELECTOR_ADC,1
    CALL  CANAL_AN1
    BTFSC SELECTOR_ADC,2
    CALL  CANAL_AN2
    BTFSC SELECTOR_ADC,3
    CALL  CANAL_AN3
    ;RLF	  SELECTOR_ADC
    RETURN
    
CANAL_AN0:
    BCF	    ADCON0,5
    BCF	    ADCON0,4
    BCF	    ADCON0,3
    BCF	    ADCON0,2
    MOVF    VALOR_ADC, W
    MOVWF   CCPRS1L
    RETURN
    
CANAL_AN1:
    BCF	    ADCON0,5
    BCF	    ADCON0,4
    BCF	    ADCON0,3
    BSF	    ADCON0,2
    RETURN
    
CANAL_AN2:
    BCF	    ADCON0,5
    BCF	    ADCON0,4
    BSF	    ADCON0,3
    BCF	    ADCON0,2
    RETURN
    
CANAL_AN3:
    BCF	    ADCON0,5
    BCF	    ADCON0,4
    BSF	    ADCON0,3
    BSF	    ADCON0,2
    RETURN
  
    
;------------------------------SUBRUTINAS---------------------------------------  
    
    
    
CONV_ADC
    ;CALL    DELAY_50MS
    BSF	    ADCON0, GO		    ; EMPIEZA LA CONVERSIÓN
CHECK_AD
    BTFSC   ADCON0, GO	       	    ; revisa que terminó la conversión
    GOTO    $-1
    BCF	    PIR1, ADIF		    ; borramos la bandera del adc			; mueve adresh al puerto b
    MOVFW   ADRESH
    MOVWF   VALOR_ADC
    MOVWF   PORTD
    RETURN               

;DELAY_50MS
;    MOVLW   .100		    ; 1US 
;    MOVWF   DELAY2
;    CALL    DELAY_500US
;    DECFSZ  DELAY2		    ;DECREMENTA CONT1
;    GOTO    $-2			    ; IR A LA POSICION DEL PC - 1
;    RETURN
;    
;DELAY_500US
;    MOVLW   .250		    ; 1US 
;    MOVWF   DELAY1	    
;    DECFSZ  DELAY1		    ;DECREMENTA CONT1
;    GOTO    $-1			    ; IR A LA POSICION DEL PC - 1
;    RETURN
    
;---------------------------- CONFIGURACIONES ----------------------------------   

CONFIG_IO
    BANKSEL TRISA
    CLRF    TRISA
    BSF	    TRISA, RA0	; RA0 COMO ENTRADA
    BSF	    TRISA, RA1	; RA1 COMO ENTRADA
    BSF	    TRISA, RA2	; RA2 COMO ENTRADA
    BSF	    TRISA, RA3	; RA3 COMO ENTRADA
    CLRF    TRISB
    BSF	    TRISB,0	;INT para cambio de pwms (RB0 como entrada)
    CLRF    TRISC
    CLRF    TRISD
    CLRF    TRISE
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH
    BSF	    ANSEL, 0	; ANS0 COMO ENTRADA ANALÃ?GICA
    BSF	    ANSEL, 1	; ANS1 COMO ENTRADA ANALÃ?GICA
    BSF	    ANSEL, 2	; ANS2 COMO ENTRADA ANALÃ?GICA
    BSF	    ANSEL, 3	; ANS3 COMO ENTRADA ANALÃ?GICA
    BANKSEL PORTA
    CLRF    PORTA
    CLRF    PORTB
    CLRF    PORTC
    CLRF    PORTD
    CLRF    PORTE
    CLRF    VALOR_ADC
    BSF     SELECTOR_ADC,0
    BSF	    SELECTOR_SERVO,0
    CLRF    CCPRS1L
    CLRF    CCPRS2L
    CLRF    CCPRS3L
    CLRF    CCPRS4L
    RETURN   
    
CONFIG_RELOJ
    BANKSEL OSCCON   
    BSF OSCCON, IRCF2
    BCF OSCCON, IRCF1
    BCF OSCCON, IRCF0		    ; FRECUECNIA DE 1MHz
    RETURN
 
CONFIG_ADC
    BANKSEL PORTA
;    BCF ADCON0, ADCS1
;    BSF ADCON0, ADCS0		; FOSC/8 RELOJ TAD
    
    BCF ADCON0, 7		; 
    BCF ADCON0, 6
    BSF ADCON0, ADON
    BCF ADCON0, 1	
    BANKSEL TRISA
    BCF ADCON1, ADFM		; JUSTIFICACIÓN A LA IZQUIERDA
    BCF ADCON1, VCFG1		; VSS COMO REFERENCIA VREF-
    BCF ADCON1, VCFG0		; VDD COMO REFERENCIA VREF+
    BANKSEL PORTA
    BSF ADCON0, ADON		; ENCIENDO EL MÓDULO ADC
    
    BANKSEL TRISA
    BSF	    TRISA, RA0		; RA0 COMO ENTRADA
    BANKSEL ANSEL
    BSF	    ANSEL, 0		; ANS0 COMO ENTRADA ANALÓGICA
    RETURN
    
CONFIG_PWM
    banksel TRISA
    MOVLW   B'00000100'
    MOVWF   TRISC
    MOVLW   .255
    MOVWF   PR2
    banksel PORTA
    BSF CCP1CON,CCP1M3
    BSF CCP1CON,CCP1M2
    BCF CCP1CON,CCP1M1
    BCF CCP1CON,CCP1M0		    ; MODO PWM
    BCF CCP1CON,P1M0
    BCF CCP1CON,P1M1
    BCF	    CCP2CON, 3
    BCF	    CCP2CON, 2
    BCF	    CCP2CON, 1
    BCF	    CCP2CON, 0
    MOVLW   B'00111101'
    MOVWF   CCPR1L	
    BSF	    CCP1CON, 5
    BSF	    CCP1CON, 4
    
    BSF	    T2CON, 0
    BCF	    T2CON, 1		    ; Prescaler 4
    
    BCF	    PIR1, TMR2IF
    BSF	    T2CON, TMR2ON	    
    BTFSS   PIR1, TMR2IF
    GOTO    $-1
    BCF	    PIR1, TMR2IF
    
    BANKSEL TRISC		    
    BCF	    TRISC, 2
    RETURN
    
    
CONFIG_INTERRUPT
    BANKSEL PORTA	    ;BANCO 0
    BSF	    INTCON, GIE	    ;SE HABILITAN LAS GLOBALES
    BSF	    INTCON, INTE  
    RETURN
    

    END
   
    

    
