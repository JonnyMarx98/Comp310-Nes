    ; Write address $3F00 (background palette) to the PPU
    LDA #$3F
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    ; Write the background palette
    LDA #$31
    STA PPUDATA
    LDA #$13
    STA PPUDATA
    LDA #$23
    STA PPUDATA
    LDA #$33
    STA PPUDATA
    LDA #$31
    STA PPUDATA
    LDA #$07
    STA PPUDATA
    LDA #$17
    STA PPUDATA
    LDA #$27
    STA PPUDATA

    ; Write address $3F10 (sprite palette) to the PPU
    LDA #$3F
    STA PPUADDR
    LDA #$10
    STA PPUADDR

    ; Write the background colour
    LDA #$21
    STA PPUDATA

    ; Write the palette 0 colours (player)
    LDA #$30
    STA PPUDATA
    LDA #$2D
    STA PPUDATA
    LDA #$16
    STA PPUDATA

    ; Write the palette 1 colours (enemy)
    LDA #$2D
    STA PPUDATA
    LDA #$1D
    STA PPUDATA
    LDA #$11
    STA PPUDATA

    ; Write the palette 2 colours (enemy when in assassination range)
    LDA #$1D
    STA PPUDATA
    LDA #$3D
    STA PPUDATA
    LDA #$12
    STA PPUDATA

    ; Write sprite data for sprite 0 (player)
    LDA #120    ; Y pos
    STA sprite_player + SPRITE_Y
    LDA #0      ; Tile No.
    STA sprite_player + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player + SPRITE_ATTRIB
    LDA #128    ; X pos
    STA sprite_player + SPRITE_X

    ; Write sprite data for sprite 1 (enemy)
    LDA #130    ; Y pos
    STA sprite_enemy + SPRITE_Y
    LDA #$05    ; Tile No.
    STA sprite_enemy + SPRITE_TILE
    LDA #1      ; Attributes
    STA sprite_enemy + SPRITE_ATTRIB
    LDA #60     ; X pos
    STA sprite_enemy + SPRITE_X

    ; Write sprite data for sprites 3 to 0 (Score sprites)
    LDA #10     ; Y pos
    STA sprite_score1 + SPRITE_Y        
    STA sprite_score2 + SPRITE_Y      
    STA sprite_score3 + SPRITE_Y 
    STA sprite_score4 + SPRITE_Y 
    STA sprite_score5 + SPRITE_Y 
    STA sprite_score_num + SPRITE_Y     
    STA sprite_score_num2 + SPRITE_Y
    LDA #$44    ; Tile No.
    STA sprite_score1 + SPRITE_TILE
    LDA #$45    ; Tile No.
    STA sprite_score2 + SPRITE_TILE
    LDA #$46    ; Tile No.
    STA sprite_score3 + SPRITE_TILE
    LDA #$47    ; Tile No.
    STA sprite_score4 + SPRITE_TILE
    LDA #$48    ; Tile No.
    STA sprite_score5 + SPRITE_TILE
    LDA #$80    ; Tile No.
    STA sprite_score_num + SPRITE_TILE
    STA sprite_score_num2 + SPRITE_TILE
    LDA #0   ; Attributes
    STA sprite_score1 + SPRITE_ATTRIB
    STA sprite_score2 + SPRITE_ATTRIB
    STA sprite_score3 + SPRITE_ATTRIB
    STA sprite_score4 + SPRITE_ATTRIB
    STA sprite_score5 + SPRITE_ATTRIB
    STA sprite_score_num + SPRITE_ATTRIB
    STA sprite_score_num2 + SPRITE_ATTRIB
    LDA #8          ; X pos
    STA sprite_score1 + SPRITE_X
    LDA #16         ; X pos
    STA sprite_score2 + SPRITE_X
    LDA #24         ; X pos
    STA sprite_score3 + SPRITE_X
    LDA #32         ; X pos
    STA sprite_score4 + SPRITE_X
    LDA #40         ; X pos
    STA sprite_score5 + SPRITE_X
    LDA #50         ; X pos
    STA sprite_score_num + SPRITE_X
    LDA #56         ; X pos
    STA sprite_score_num2 + SPRITE_X