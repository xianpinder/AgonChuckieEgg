;============================================================================================================
;
; 8888888 888b    888 8888888 88888888888 
;   888   8888b   888   888       888     
;   888   88888b  888   888       888     
;   888   888Y88b 888   888       888     
;   888   888 Y88b888   888       888     
;   888   888  Y88888   888       888     
;   888   888   Y8888   888       888     
; 8888888 888    Y888 8888888     888     
;
;============================================================================================================
;
; Agon binary startup code. Needs to be first code included.
;
;============================================================================================================

                    ASSUME  ADL=1
                    org     $40000
                    jp      begin$
    
                    align   64
                    db      "MOS",0,1
begin$:
                    push    ix
                    push    iy
                    call    main
                    pop     iy
                    pop     ix
                    or      a
                    sbc     hl,hl
                    ret
