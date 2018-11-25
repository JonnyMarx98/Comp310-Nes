                                   ;            \1       \2       \3      \4        \5            \6             \7   
CheckCollisionWithWall .macro ; parameters: scroll_x, player_y, wall_x, wall_w, wall_h, no_collision_label, on_top_label
    ; if there is a collision, execution continues immediately after this macro
    ; else, jump to no_collision_label
    LDA \1                              
    CLC
    CMP \3                                         ; if scroll_x >= wall_x check next collision, else branch to no_collision_label 
    BCC \6
    CLC
    CMP \3 + \4 + (PLAYER_X_OFFSET-1)              ; if scroll_x >= wall_x + wall_w + player_x_offset then no collision, else check Y collision
    BCS \6
    ; Check if player Y collision with wall height
    LDA #SCREEN_BOTTOM
    SEC
    SBC \5 - PLAYER_HEIGHT                         ; Subtract wall height and player height from the screen bottom to find top of of wall.
    CMP \2                                         ; If Screen_botttom - wall_h - Player_height >= player_y then player is on top of wall
    BCS \7                                         ; Branch to the on_top_label 
    .endm

SetClimbingActive .macro ; parameters: true(1) or false(0), collision_active (left or right)
    LDA \1
    STA \2
    .endm

SetClimbingSprite .macro ; parameters: climbing_direction left(0) or Right(1)
    .if \1 < 1
    ; If climbing direction is left
    SetSpriteTile #$07, sprite_player               ; Sets sprite to climbing left sprite
    .else
    ; Else climbing direction must be right
    SetSpriteTile #$06, sprite_player               ; Sets sprite to climbing right sprite
    .endif
    .endm 

SetBottom .macro    ; parameters: wall_h
    LDA #(SCREEN_BOTTOM + PLAYER_HEIGHT - \1)       ; Load SCREEN BOTTOM + PLAYER HEIGHT - WALL HEIGHT into accumulator
    STA screen_bottom                               ; Store in screen_bottom 
    JMP NoClimbingActive
    .endm

Climb .macro
    ; Update player Y position
    LDA sprite_player + SPRITE_Y                    ; Load player Y into accumulator
    SEC 
    SBC #1                                          ; Minus 1 from player Y
    STA sprite_player + SPRITE_Y                    ; Store value back into player Y
    ; Stop playing from falling from gravity (or moving up from jumping)
    ResetPlayerSpeed
    .endm

ResetPlayerSpeed .macro 
    LDA #0                                          ; Load 0 into accumulator
    STA player_jump_speed                           ; Store into player_jump_speed and player_jump_speed+1
    LDA #0
    STA player_jump_speed+1
    .endm

PlayerJump .macro 
    ; Jump by setting player speed
    LDA #LOW(JUMP_SPEED)
    STA player_jump_speed
    LDA #HIGH(JUMP_SPEED)
    STA player_jump_speed+1
    .endm

SetSpriteTile .macro ; parameters: tile_number, sprite
    LDA \1                                          ; Loads tile number into accumulator
    STA \2+SPRITE_TILE                              ; Stores value into sprite
    .endm

IncrementScore .macro
    LDA score                                       ; Loads score into accumulator
    CLC                                             ; Clear carry flag                            
    ADC #1                                          ; Adds 1
    STA score                                       ; Stores back into score
    .endm

ScrollBackground .macro  ; params: Left(0) or Right(1), scroll speed,  no_scroll_wrap_label, reset (0)
    ; If resetting scroll_x, jump over scrolling code
    .if \4 > 0                                      
    LDA scroll_x
    .if \1 < 1                                      ; If direction is 0 scroll left, else scroll right 
    SEC
    SBC \2                                          ; Subtract scroll speed from scroll_x
    .else
    CLC 
    ADC \2                                          ; Add scroll speed to scroll_x
    .endif
    STA scroll_x                                    ; Store value back into scroll_x
    STA PPUSCROLL
    ; else reset scroll_x
    .else                                           
    LDA #0                                          
    STA scroll_x
    STA PPUSCROLL
    .endif

    LDA sprite_enemy+SPRITE_X
    ; If direction is 0 scroll left
    .if \1 < 1                                      
    CLC
    ADC \2                                          ; Add scroll speed to playerX
    ; else scroll right 
    .else
    LDA sprite_enemy+SPRITE_X
    SEC
    SBC \2                                          ; Subtract scroll speed from playerX
    .endif
    STA sprite_enemy+SPRITE_X
    BCC \3                                          ; If carry flag is not clear scroll_x has wrapped, else branch to no_scroll_wrap_label  
    ; scroll_x has wrapped, so switch scroll_page
    LDA scroll_page
    EOR #1
    STA scroll_page
    ORA #%10000000
    STA PPUCTRL
; No scroll wrap label
\3:
    LDA #0
    STA PPUSCROLL  
    .endm

SpawnArrow .macro
    ; Set arrow to active
    LDA #1
    STA arrow_active
    ; Spawn arrow sprite at player
    LDA sprite_player + SPRITE_Y   ; Y pos
    STA sprite_arrow + SPRITE_Y
    SetSpriteTile #2, sprite_arrow
    LDA #0                         ; Attributes 
    STA sprite_arrow + SPRITE_ATTRIB
    LDA sprite_player + SPRITE_X   ; X pos
    STA sprite_arrow + SPRITE_X
    LDA arrow_direction
    BEQ ReadB_Done
    ; Flip the sprite if shooting left (if direction == 1)
    LDA sprite_arrow+SPRITE_ATTRIB
    EOR #%01000000
    STA sprite_arrow+SPRITE_ATTRIB
    .endm

CollisionCheck .macro
    ; CheckCollisionWithWall parameters: scroll_x, player_y, wall_x, wall_w, wall_h, no_collision_label, on_top_label
    CheckCollisionWithWall \1, \2, \3, \4, \5, \6, \7
    ; SetClimbingActive      parameters: true(1) or false(0), collision_active (left or right)
    SetClimbingActive #1, \8   ; Set climbing to true
    ; SetClimbingSprite      parameters: climbing_direction left(0) or Right(1)
    SetClimbingSprite \9
    LDA #0
    STA on_top_wall           ; Set on_top_wall (player is on top of a wall) to true
    JMP CollisionChecksDone
\7:
    LDA #1
    STA on_top_wall           ; Set on_top_wall (player is on top of a wall) to true
    SetBottom \5
    .endm 

assassinateEnemy .macro  
    LDA player_jump_speed    ; Low 8 bits
    CLC
    ADC #LOW(ASSASSIN_FALL_SPEED)
    STA player_jump_speed
    LDA player_jump_speed+1  ; High 8 bits
    ADC #HIGH(ASSASSIN_FALL_SPEED)  ; NB: *don't* clear the carry flag!
    STA player_jump_speed+1
    LDA sprite_player+SPRITE_X
    CMP sprite_enemy+SPRITE_X       ; if playerX >= enemyX set carry flag
    BCS assassinateLeft
    ; Scroll background twice normal speed
    ; assassinate right
    ScrollBackground #1, #2, Scroll_NoWrap4, #1
    ; Set sprite tile to assassinate tile
    SetSpriteTile #$16, sprite_player  
    JMP UpdatePlayerPosition
assassinateLeft:
    ScrollBackground #0, #2, Scroll_NoWrap5, #1
    ; Set sprite tile to assassinate tile
    SetSpriteTile #$17, sprite_player
    JMP UpdatePlayerPosition
    .endm

CheckCollisionWithEnemy .macro ; parameters: object_x, object_y, object_hit_x, object_hit_y, object_hit_w, object_hit_h, no_collision_label
    ; if there is a collision, execution continues immediately after this macro
    ; else, jump to no_collision_label
    LDA sprite_enemy+SPRITE_X  ; Calculate x_enemy - object_hit_w (x1-w2)
    .if \3 > 0
    SEC
    SBC \3
    .endif
    SEC
    SBC \5+1                      ; Assume w2 = 8
    CMP \1                        ; Compare with object_x (x2)
    BCS \7                        ; Branch if x1-w2-1-ARROW_HITBOX_X >= x2  ie x1-w2 > x2
    CLC
    ADC \5+ENEMY_HITBOX_WIDTH+1   ; Calculate x_enemy + w_enemy (x1+w1) assuming w1 = 8
    CMP \1                        ; Compare with object_x (x2)
    BCC \7                        ; Branch if x1+w1+1+ARROW_HITBOX_X <= x2

    LDA sprite_enemy+SPRITE_Y ; Calculate y_enemy - h_arrow (y1-h2)
    .if \3 > 0
    SEC
    SBC \4 
    .endif
    SEC
    SBC \6+1                      ; Assume h2 = 8
    CMP \2                        ; Compare with object_y (y2)
    BCS \7                        ; Branch if y1-h2-1-ARROW_HITBOX_Y >= y2
    CLC
    ADC \6+ENEMY_HITBOX_WIDTH+1   ; Calculate y_enemy + h_enemy (y1+h1) assuming h1 = 8
    CMP \2                        ; Compare with object_y (y2)
    BCC \7                        ; Branch if y1+h1+1+ARROW_HITBOX_Y <= y2
    .endm