#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#


;address for ports of first 8255
porta1 equ 00h
portb1 equ 02h
portc1 equ 04h
creg1  equ 06h

;address for ports of second 8255
porta2 equ 08h
portb2 equ 0ah
portc2 equ 0ch
creg2  equ 0eh


     
; add your code here

        jmp     st1 
        db     5 dup(0)

;IVT entry for nmi
         
        dw     nmi_isr
        dw     0000
        db     1012 dup(0)
     
		st1:   

		mov ax,0200h
		mov ds,ax
		mov es,ax
		mov ss,ax

		mov sp,0FFFEH
        		
		mov al,81h
		out creg2,al    ;initializing output : porta2,portb2,portc2upper 
						;				input: portc2 lower
        
        mov al,91h 		;initializing output : portb1,portc1 upper 
		out creg1,al 					;input :porta1,portc1 lower  

   x100:jmp x100
			
	
nmi_isr:		
		
		mov al,81h
		out creg2,al    ;initializing output : porta2,portb2,portc2upper 
						;				input: portc2 lower
		mov al,91h				;initializing output : portb1,portc1 upper 
		out creg1,al 					;input :porta1,portc1 lower
		 
		mov ax,781
		mov [0020h],ax  ;storing the conversion factor in memory
		mov bx,0022h

;converting the analog value of first load cell into digital using adc 0808--------------------------
	 
        mov al,00000000b
        out portb1,al
	 
        mov al,00001110b  	;resetting soc to 0
		out creg1,al
		
		mov al,00001011b
		out creg1,al		;setting ale to 1  
		           
		mov al,00001111b  	;setting soc to 1 
		out creg1,al
          
		mov al,00001010b
		out creg1,al		;resetting ale to 0
	                 
		mov al,00001110b	 ;resetting soc to 0
		out creg1,al
                    

x11:	in al,portc2		;polling to check for end of conversion
		and al,00000001b
		jz x11	
		
		mov al,00001011b
		out creg2,al
	             
        mov al,91h 		
    	out creg1,al
        
		in al,porta1
    	mov [bx],al   	
    	
		mov al,0001010b
		out creg2,al  
		
;converting the analog value of second load cell into digital---------------------------------------------

        mov al,91h 		
    	out creg1,al

        mov al,00000001b
        out portb1,al
		 		 
    	mov al,00001110b  	;setting soc to 0
		out creg1,al
          
		mov al,00001011b
		out creg1,al		;setting ale to 1 
		           
		mov al,00001111b  	;setting soc to 1
		out creg1,al
          
		mov al,00001010b
		out creg1,al		;resetting ale to 0
	                 
		mov al,00001110b	 ;resetting soc to 0
		out creg1,al
 
		
x12:	in al,portc2			;polling to check for end of conversion
		and al,00000001b
		jz x12
		
		mov al,00001011b
		out creg2,al
          
	    mov al,91h 		
        out creg1,al
        
        in al,porta1
    	mov [bx+1],al  
    	
		   
;converting the analog value of third load cell into digital;;;;;;;;;;;;;

        mov al,0001010b
		out creg2,al
		
		mov al,91h 		
		out creg1,al

        mov al,00000010b
        out portb1,al
		 		 
    	mov al,00001110b  	;setting soc to 0
		out creg1,al
          
		mov al,00001011b
		out creg1,al		;setting ale to 1  
		           
		mov al,00001111b  	;setting soc to 1
		out creg1,al
          
		mov al,00001010b
		out creg1,al		;resetting ale to 0
	                 
		mov al,00001110b	 ;resetting soc to 0
		out creg1,al
                   
x13:	in al,portc2			;polling to check for end of conversion
		and al,00000001b
		jz x13          
         
		mov al,00001011b
		out creg2,al	                
        
		mov al,91h 		
	    out creg1,al
        
	    in al,porta1
    	mov [bx+2],al  
    	
		mov al,0001010b
		out creg2,al
		 

	  
;weight calculation

		mov ax,[0020h]	 ;moving the multiplier into ax
		mov ch,0
		mov cl,[bx] 	 ;moving the first voltage value from memory             
		mul cx 			 ;multiplying the two

		mov cx,1000
		div cx 			 ;dividing by 1000 to get the weight 
		mov [0030h],ax
		mov [0032h],dx   ;moving the result back to memory

;calculating for the other two load cells

		mov ax,[0020h]   ;moving the multiplier value from memory
		mov ch,0
		mov cl,[bx+1]    ;moving the first voltage value from memory
		mul cx           ;multiply the multiplier and the voltage output
		mov cx,1000
		div cx           ;dividing by 1000 to get the weight
		mov [0034h],ax
		mov [0036h],dx   ;moving the result back to memory


		mov ax,[0020h]   ;moving the multiplier value from memory
		mov ch,0
		mov cl,[bx+2]    ;moving the first voltage value from memory
		mul cx           ;multiply the multiplier and the voltage output
		mov cx,1000
		div cx           ;dividing by 1000 to get the weight
		mov [0038h],ax
		mov [0040h],dx   ;moving the result back to memory

		mov bx,[0030h]
		add bx,[0034h]
		add bx,[0038h]   ;adding all the 3 quotient values
	
		mov ax,[0032h]
		add ax,[0036h]
		add ax,[0040h]   ;adding all the remainder values

		mov dx,0
		mov cx,1000
		div cx  	    ;dividing the remainder by 1000
		add bx,ax 	    ;adding the quotient to the overall quotient
						;Overall Quotient is stored in bx and
    					;overall remainder is stored in dx 
    	mov [0054h],dx  ;moving remainder
		
		mov cl,3
		mov ax,bx
		div cl		   

		mov [0050h],ax 	  
		
		mov cx,1000 
		mov al,ah
		mov ah,0
		mul cx			;multiplying remainder of division of quotient of weight when divided by 3--- with 1000
  
        add ax,[0054h]
      
		mov cx,3    
		mov dx,0
        div cx

    	mov dx,ax        ;now dx will have the decimal of the weight
		mov cl,[0050h]
		mov ch,0
  
		mov bx,cx		; bx will have the integer part of weight
		        
		cmp bx,99 	;comparing with 99
		jb weight
		
		cmp bx,99
		ja buzzer
		
		cmp dx,0000h
		je weight

buzzer:	
	    mov al,00001001b
		out creg2,al	  ;sounds the buzzer	
		call delay1
				
		jmp buzzer
		
weight:
;dx has the decimal and bx has the integer
;extracting the digits of integer
		mov ax,bx
		mov bh,0ah 		 ;moving decimal value 10 into bh
		div bh 			 ;dividing by 10 is sufficient as the quotient is less than 99
						 ;it will store the unit digit in ah & tens digit in al
		mov [0040h],al   ;0040h contains the tens digit
		mov [0042h],ah   ;0041h contains the unit digit


;starting the display process
display:
		mov al,00001110b    ;port a as output c upper as input portb mode1 port b as input port c lower as output
		out creg2,al
		
;display the first digit
				
		mov al,81h			
		out creg2,al    

		mov al,[0040h]  ;moving the first digit to al	
		out porta2,al 	;moving the first digit into the port
            			;A of 8255(2) which is connected to 7447

		mov al,00000001b
		out portb2,al		;value displayed on first display

        call delay1
        
        mov al,00000000b
		out portb2,al	
;display the second digit
                      
		mov al,[0042h]  ;moving the second digit to al
		out porta2,al 	;moving the second digit into the port
						;A of 8255(2) which is connected to 7447

        mov al,00000010b
		out portb2,al		;value displayed on second display
    
        call delay1
                
        mov al,00000000b
		out portb2,al	         
	
		jmp display

delay1  proc   near 
          
        push cx 
        mov cx,1
   ps1: nop 
        loop ps1 
        pop cx 
        ret 
delay1  endp         
iret