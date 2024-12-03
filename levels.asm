;============================================================================================================
;
; 888      8888888888 888     888 8888888888 888      .d8888b.  
; 888      888        888     888 888        888     d88P  Y88b 
; 888      888        888     888 888        888     Y88b.      
; 888      8888888    Y88b   d88P 8888888    888      "Y888b.   
; 888      888         Y88b d88P  888        888         "Y88b. 
; 888      888          Y88o88P   888        888           "888 
; 888      888           Y888P    888        888     Y88b  d88P 
; 88888888 8888888888     Y8P     8888888888 88888888 "Y8888P"  
;
;============================================================================================================
;
; Chuckie Egg level data. Copied from the BBC Micro version.
;
;============================================================================================================

level_array:
                    dl      level_1
                    dl      level_2
                    dl      level_3
                    dl      level_4
                    dl      level_5
                    dl      level_6
                    dl      level_7
                    dl      level_8

level_1:
                    db	    13				; number of platforms
                    db	    4				; number of ladders
                    db	    0				; lifts flag
                    db	    10				; number of grain piles
                    db	    2				; number of ostriches to start with
; platforms y, start_x, end_x
                    db      1, 0, 19
                    db      6, 1, 18
                    db      11, 2, 8
                    db      11, 14, 18
                    db      12, 9, 10
                    db      13, 11, 12
                    db      14, 13, 14
                    db      15, 15, 16
                    db      16, 3, 7
                    db      17, 9, 11
                    db      21, 5, 9
                    db      21, 11, 16
                    db      21, 18, 19
; ladders x, start_y, end_y
                    db      3, 7, 13
                    db      7, 2, 23
                    db      11, 2, 8
                    db      16, 2, 8
; lift
			        ; no lifts on level 1
; eggs x,y
                    db      4, 2
                    db      1, 7
                    db      13, 7
                    db      18, 7
                    db      2, 12
                    db      10, 13
                    db      17, 12
                    db      4, 17
                    db      10, 18
                    db      6, 22
                    db      13, 22
                    db      19, 22
; grain x,y
                    db      2, 2
                    db      13, 2
                    db      5, 7
                    db      14, 7
                    db      5, 12
                    db      15, 12
                    db      16, 16
                    db      11, 18
                    db      9, 22
                    db      14, 22
; ostriches x,y
                    db      5, 17
                    db      8, 22
                    db      4, 12
                    db      6, 7
                    db      12, 2

;============================================================================================================

level_2:
                    db	    13				; number of platforms
                    db	    8				; number of ladders
                    db	    0				; lifts flag
                    db	    7				; number of grain piles
                    db	    3				; number of ostriches to start with
;platforms
                    db      1, 0, 3
                    db      1, 5, 19
                    db      6, 0, 6
                    db      6, 8, 10
                    db      6, 12, 14
                    db      6, 16, 19
                    db      11, 0, 3
                    db      11, 5, 14
                    db      11, 16, 19
                    db      16, 0, 10
                    db      16, 12, 19
                    db      21, 4, 10
                    db      21, 12, 19
;ladders
                    db      2, 2, 18
                    db      4, 17, 23
                    db      6, 7, 18
                    db      9, 2, 8
                    db      9, 12, 23
                    db      13, 12, 18
                    db      17, 2, 13
                    db      17, 17, 23
;lift
;eggs
                    db      5, 2
                    db      12, 2
                    db      0, 7
                    db      4, 7
                    db      13, 7
                    db      0, 12
                    db      7, 12
                    db      19, 12
                    db      7, 17
                    db      7, 22
                    db      15, 22
                    db      19, 22
;grain
                    db      0, 2
                    db      3, 2
                    db      15, 2
                    db      16, 7
                    db      0, 17
                    db      10, 17
                    db      12, 22
;ostriches
                    db      6, 22
                    db      1, 2
                    db      18, 12
                    db      11, 12
                    db      13, 22


level_3:
                    db	    24				; number of platforms
                    db	    7				; number of ladders
                    db	    1				; lifts flag
                    db	    10				; number of grain piles
                    db	    3				; number of ostriches to start with
;platforms
                    db      1, 0, 2
                    db      2, 3, 4
                    db      1, 7, 9
                    db      1, 11, 19
                    db      5, 15, 18
                    db      10, 0, 4
                    db      15, 0, 3
                    db      19, 3, 4
                    db      6, 7, 10
                    db      6, 12, 12
                    db      7, 14, 14
                    db      8, 15, 15
                    db      9, 17, 17
                    db      10, 18, 19
                    db      12, 12, 13
                    db      12, 15, 15
                    db      15, 18, 19
                    db      16, 17, 17
                    db      17, 15, 15
                    db      18, 12, 13
                    db      19, 7, 11
                    db      21, 13, 15
                    db      20, 16, 16
                    db      20, 18, 19
;ladders
                    db      1, 2, 12
                    db      3, 11, 21
                    db      8, 7, 21
                    db      10, 7, 21
                    db      13, 19, 23
                    db      18, 2, 7
                    db      19, 11, 17
;lift
                    db      5
;eggs
                    db      4, 3
                    db      15, 2
                    db      16, 6
                    db      4, 11
                    db      4, 20
                    db      9, 7
                    db      15, 9
                    db      15, 13
                    db      1, 16
                    db      17, 17
                    db      19, 18
                    db      9, 21
;grain
                    db      2, 2
                    db      2, 11
                    db      7, 7
                    db      7, 20
                    db      0, 16
                    db      13, 2
                    db      12, 19
                    db      15, 18
                    db      13, 13
                    db      18, 21
;ostriches
                    db      2, 16
                    db      9, 20
                    db      17, 6
                    db      0, 2
                    db      8, 7

;============================================================================================================
level_4:
                    db	    26				; number of platforms
                    db	    5				; number of ladders
                    db	    1				; lifts flag
                    db	    6				; number of grain piles
                    db	    4				; number of ostriches to start with
;platforms
                    db      1, 0, 4
                    db      1, 6, 10
                    db      1, 13, 19
                    db      6, 0, 4
                    db      6, 7, 10
                    db      6, 13, 17
                    db      5, 19, 19
                    db      12, 0, 1
                    db      13, 3, 3
                    db      14, 5, 5
                    db      15, 7, 8
                    db      11, 7, 8
                    db      11, 13, 16
                    db      10, 18, 19
                    db      16, 8, 10
                    db      17, 0, 0
                    db      18, 2, 2
                    db      19, 3, 3
                    db      20, 4, 4
                    db      21, 5, 5
                    db      21, 7, 10
                    db      16, 13, 14
                    db      16, 16, 16
                    db      16, 18, 19
                    db      21, 13, 15
                    db      21, 17, 19
;ladders
                    db      3, 2, 8
                    db      8, 2, 23
                    db      14, 12, 23
                    db      15, 2, 8
                    db      19, 16, 23
;lift
                    db      11
;eggs
                    db      0, 2
                    db      0, 13
                    db      0, 18
                    db      7, 7
                    db      9, 17
                    db      13, 2
                    db      16, 7
                    db      13, 12
                    db      19, 11
                    db      17, 16
                    db      16, 21
                    db      16, 24
;grain
                    db      0, 7
                    db      10, 2
                    db      18, 2
                    db      5, 15
                    db      9, 22
                    db      13, 22
;ostriches
                    db      10, 22
                    db      17, 22
                    db      17, 2
                    db      4, 2
                    db      10, 7
;============================================================================================================
level_5:
                    db	    17				; number of platforms
                    db	    9				; number of ladders
                    db	    1				; lifts flag
                    db	    13				; number of grain piles
                    db	    4				; number of ostriches to start with
;platforms
                    db      1, 0, 1
                    db      1, 3, 11
                    db      1, 13, 15
                    db      1, 18, 19
                    db      6, 0, 5
                    db      6, 9, 12
                    db      6, 14, 15
                    db      11, 0, 5
                    db      11, 10, 15
                    db      11, 19, 19
                    db      16, 0, 5
                    db      21, 3, 7
                    db      20, 9, 9
                    db      19, 11, 13
                    db      18, 14, 14
                    db      22, 12, 15
                    db      21, 18, 19
;ladders
                    db      3, 2, 8
                    db      2, 12, 18
                    db      4, 12, 23
                    db      7, 2, 7
                    db      7, 10, 17
                    db      10, 2, 8
                    db      12, 7, 13
                    db      12, 20, 24
                    db      14, 2, 8
;lift
                    db      16
;eggs
                    db      0, 2
                    db      0, 7
                    db      0, 12
                    db      0, 17
                    db      5, 7
                    db      5, 22
                    db      9, 11
                    db      13, 6
                    db      11, 20
                    db      13, 23
                    db      19, 12
                    db      19, 22
;grain
                    db      4, 2
                    db      5, 2
                    db      6, 2
                    db      13, 2
                    db      15, 2
                    db      18, 2
                    db      10, 12
                    db      15, 12
                    db      3, 22
                    db      6, 22
                    db      7, 22
                    db      15, 23
                    db      18, 22
;ostriches
                    db      1, 7
                    db      3, 12
                    db      1, 17
                    db      14, 12
                    db      15, 7
;============================================================================================================
level_6:
                    db	    16				; number of platforms
                    db	    6				; number of ladders
                    db	    1				; lifts flag
                    db	    9				; number of grain piles
                    db	    4				; number of ostriches to start with
;platforms
                    db      1, 0, 2
                    db      1, 6, 8
                    db      1, 11, 14
                    db      6, 0, 1
                    db      6, 3, 5
                    db      6, 12, 14
                    db      11, 2, 7
                    db      11, 12, 17
                    db      10, 17, 19
                    db      16, 0, 5
                    db      16, 16, 19
                    db      21, 6, 6
                    db      21, 8, 8
                    db      20, 12, 17
                    db      22, 17, 19
                    db      2, 17, 17
;ladders
                    db      0, 2, 8
                    db      4, 4, 18
                    db      14, 7, 13
                    db      14, 19, 23
                    db      17, 2, 13
                    db      17, 16, 24
;lift
                    db      9
;eggs
                    db      2, 2
                    db      16, 2
                    db      5, 7
                    db      12, 7
                    db      12, 12
                    db      16, 12
                    db      7, 17
                    db      3, 21
                    db      6, 22
                    db      12, 21
                    db      19, 17
                    db      19, 23
;grain
                    db      11, 2
                    db      12, 2
                    db      13, 2
                    db      14, 2
                    db      0, 17
                    db      2, 17
                    db      3, 17
                    db      7, 12
                    db      19, 11
;ostriches
                    db      1, 17
                    db      1, 2
                    db      18, 17
                    db      13, 7
                    db      18, 11
;============================================================================================================
level_7:
                    db	    23				; number of platforms
                    db	    7				; number of ladders
                    db	    1				; lifts flag
                    db	    4				; number of grain piles
                    db	    3				; number of ostriches to start with
;platforms
                    db      21, 11, 16
                    db      16, 0, 4
                    db      16, 6, 7
                    db      11, 0, 2
                    db      6, 1, 3
                    db      4, 0, 1
                    db      1, 3, 4
                    db      2, 5, 6
                    db      1, 7, 8
                    db      2, 9, 9
                    db      3, 9, 9
                    db      3, 12, 12
                    db      8, 5, 8
                    db      9, 5, 5
                    db      10, 5, 5
                    db      11, 5, 5
                    db      12, 5, 5
                    db      11, 8, 8
                    db      12, 8, 8
                    db      15, 12, 15
                    db      11, 10, 11
                    db      9, 14, 16
                    db      2, 15, 16
;ladders
                    db      1, 2, 18
                    db      3, 2, 8
                    db      5, 20, 24
                    db      7, 20, 24
                    db      9, 20, 24
                    db      13, 16, 23
                    db      15, 10, 17
;lift
                    db      18
;eggs
                    db      6, 23
                    db      8, 23
                    db      10, 23
                    db      15, 22
                    db      7, 17
                    db      2, 3
                    db      7, 9
                    db      11, 12
                    db      16, 15
                    db      16, 10
                    db      12, 4
                    db      17, 2
;grain
                    db      2, 7
                    db      3, 17
                    db      8, 9
                    db      12, 22
;ostriches
                    db      13, 22
                    db      1, 17
                    db      14, 10
                    db      0, 5
                    db      2, 12
;============================================================================================================
level_8:
                    db	    15				; number of platforms
                    db	    6				; number of ladders
                    db	    0				; lifts flag
                    db	    16				; number of grain piles
                    db	    3				; number of ostriches to start with
;platforms
                    db      1, 0, 19
                    db      6, 2, 4
                    db      6, 7, 13
                    db      6, 16, 18
                    db      11, 2, 5
                    db      11, 8, 12
                    db      11, 15, 18
                    db      16, 3, 6
                    db      16, 9, 11
                    db      16, 14, 17
                    db      21, 3, 3
                    db      21, 6, 6
                    db      21, 8, 12
                    db      21, 14, 14
                    db      21, 17, 17
;ladders
                    db      3, 2, 8
                    db      17, 2, 8
                    db      10, 7, 13
                    db      4, 12, 18
                    db      16, 12, 18
                    db      10, 17, 23
;lift
;eggs
                    db      5, 6
                    db      15, 6
                    db      6, 11
                    db      14, 11
                    db      8, 16
                    db      12, 16
                    db      5, 21
                    db      15, 21
                    db      7, 21
                    db      13, 21
                    db      3, 24
                    db      17, 24
;grain
                    db      1, 2
                    db      2, 2
                    db      4, 2
                    db      5, 2
                    db      6, 2
                    db      8, 2
                    db      9, 2
                    db      10, 2
                    db      11, 2
                    db      12, 2
                    db      13, 2
                    db      14, 2
                    db      15, 2
                    db      16, 2
                    db      18, 2
                    db      19, 2
;ostriches
                    db      17, 2
                    db      10, 12
                    db      10, 22
                    db      3, 17
                    db      17, 17
;============================================================================================================
