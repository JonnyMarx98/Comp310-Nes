;------------------------------ INITIALISE GAME-----------------------;
InitialiseGame: ; Begin subroutine     

    ; Reset the PPU high/low latch
    LDA PPUSTATUS

    ; Write sprite data and initialise sprites
    INCLUDE "sprite_data.asm"

    ; Load nametable data 
    LDA #$20   ; Write address $2000 to PPUADDR register
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDA #LOW(NametableData)
    STA nametable_address
    LDA #HIGH(NametableData)
    STA nametable_address+1
LoadNametable_OuterLoop:
    LDY #0
LoadNametable_InnerLoop:
    LDA [nametable_address], Y
    BEQ LoadNametable_End
    STA PPUDATA
    INY
    BNE LoadNametable_InnerLoop
    INC nametable_address+1
    JMP LoadNametable_OuterLoop
LoadNametable_End:

    ; Load attribute data
    LDA #$23   ; Write address $23C0 to PPUADDR register
    STA PPUADDR
    LDA #$C0
    STA PPUADDR

    LDA #%01010101
    LDX #64
LoadAttributes_Loop:
    STA PPUDATA
    DEX
    BNE LoadAttributes_Loop
    
    ; Load nametable data 
    LDA #$24        ; Write address $2000 to PPUADDR register
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    LDA #LOW(NametableData)
    STA nametable_address
    LDA #HIGH(NametableData)
    STA nametable_address+1
LoadNametable2_OuterLoop:
    LDY #0
LoadNametable2_InnerLoop:
    LDA [nametable_address], Y
    BEQ LoadNametable2_End
    STA PPUDATA
    INY
    BNE LoadNametable2_InnerLoop
    INC nametable_address+1
    JMP LoadNametable2_OuterLoop
LoadNametable2_End:

    ; Load attribute data
    LDA #$27        ; Write address $23C0 to PPUADDR register
    STA PPUADDR
    LDA #$C0
    STA PPUADDR

    LDA #%01010101
    LDX #64
LoadAttributes2_Loop:
    STA PPUDATA
    DEX
    BNE LoadAttributes2_Loop
    

    RTS    ; End subroutine ; End subroutine

;------------------------------ READ JOYPAD-----------------------;
ReadJoypad: ; Begin subroutine

;----- INITIALISE CONTROLLER-----;

; Initialise controller 1
    LDA #1
    STA JOY1
    LDA #0
    STA JOY1

    ;Read joypad state
    LDX #0
    STX joypad1_state
ReadController:
    LDA JOY1
    LSR A
    ROL joypad1_state
    INX 
    CPX #8
    BNE ReadController

;----------- RIGHT BUTTON--------;

    LDA joypad1_state
    AND #BUTTON_RIGHT
    BEQ ReadRightDone_JUMP         ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button
    JMP RightPressed
ReadRightDone_JUMP:
    JMP ReadRight_Done 
RightPressed:
    ; If not climbing branch to NoWallCollision
    LDA climbing_right_active
    BEQ NoWallCollision
    ; Stop jump by reseting speed 
    ResetPlayerSpeed
    ; Climb
    Climb
    JMP ReadRight_Done
NoWallCollision:
    ; Scrolls background left (so player moves right)
    ScrollBackground #1, #1, Scroll_NoWrap, #1
    ; Set arrow direction
    LDA arrow_active
    BNE SetNextArrowDirection      ; If arrow is active, set next arrow direction so it doesn't affect the current active arrow 
    LDA #0
    STA arrow_direction            ; If arrow is not active, set the arrow direction to right
    JMP UpdateSpriteTile
SetNextArrowDirection:
    LDA #0
    STA next_arrow_direction       ; Set next arrow direction to right
UpdateSpriteTile:
    ; Update sprite tile (ANIMATION)
    LDA player_anim_state
    BEQ ZeroState                  ; If anim state is 0 branch to ZeroState
    ; Accumulator is 1
    STA sprite_player+SPRITE_TILE  ; Else set the sprite tile to tile 01 (state 1 right)
    LDA #0
    STA player_anim_state          ; Switch anim state
    JMP SpriteTile_Updated
ZeroState:
    ; Accumulator is 0
    STA sprite_player+SPRITE_TILE  ; Set the sprite tile to tile 00 (state 0 right)
    LDA #1
    STA player_anim_state          ; Switch anim state
SpriteTile_Updated:
    ; Check if player is on a left wall
    LDA climbing_left_active   
    BNE WallJumpRight              ; If player is climbing a left wall, branch to WallJumpRight
    JMP ReadRight_Done             ; Else done reading right
WallJumpRight:
    PlayerJump
ReadRight_Done:

;----------- DOWN BUTTON--------;

    LDA joypad1_state
    AND #BUTTON_DOWN
    BEQ ReadDown_Done              ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button

ReadDown_Done:

;----------- LEFT BUTTON--------;

    LDA joypad1_state
    AND #BUTTON_LEFT
    BEQ ReadLeftDone_JUMP          ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button 
    JMP LeftPressed
ReadLeftDone_JUMP:
    JMP ReadLeft_Done
LeftPressed:
    ; If not climbing branch to NoWallCollision
    LDA climbing_left_active
    BEQ NoWallCollision2
    ; Stop jump by reseting speed 
    ResetPlayerSpeed
    ; Call climb macro
    Climb
    JMP ReadLeft_Done

NoWallCollision2:
    ; Scrolls background right (so player moves left)
    ScrollBackground #0, #1, Scroll_NoWrap2, #1
    LDA arrow_active
    BNE SetNextArrowDirection2          ; If arrow is active, set next arrow direction so it doesn't affect the current active arrow 
    LDA #1
    STA arrow_direction                 ; If arrow is not active, set the arrow direction to left
    JMP UpdateSpriteTile2
SetNextArrowDirection2:
    LDA #1
    STA next_arrow_direction            ; Set next arrow direction to left
UpdateSpriteTile2:
    ; Update sprite tile (ANIMATION)
    LDA player_anim_state
    BEQ ZeroState2                      ; If anim state is 0 branch to ZeroState2 
    SetSpriteTile #$15, sprite_player   ; Else set the sprite tile to tile 15 (state 1 left)
    LDA #0
    STA player_anim_state               ; Switch anim state
    JMP SpriteTile_Updated2
ZeroState2:
    SetSpriteTile #$14, sprite_player   ; Set the sprite tile to tile 14 (state 0 left)
    LDA #1
    STA player_anim_state               ; Switch anim state
SpriteTile_Updated2: 
    ; Check if player is on right wall
    LDA climbing_right_active   
    BNE WallJumpLeft                    ; If player is climbing a right wall, branch to WallJumpLeft
    JMP ReadLeft_Done
WallJumpLeft:
    PlayerJump
    
ReadLeft_Done:

;----------- UP BUTTON--------;

    LDA joypad1_state
    AND #BUTTON_UP
    BEQ ReadUp_Done                ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button

    ; Check if player is on ground
    LDA screen_bottom ; - 2        ; Load ScreenBottom into accumulator
    SEC
    SBC #2
    CLC                            ; clear carry flag
    CMP sprite_player+SPRITE_Y     ; if ScreenBottom >= PlayerY player can jump, else read up done
    BCS ReadUp_Done
    PlayerJump

ReadUp_Done:

;----------- A BUTTON--------;

    LDA joypad1_state
    AND #BUTTON_A
    BEQ ReadA_Done                 ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button
    LDA assassinate                
    BNE ReadA_Done                 ; if already assassinating branch to ReadA_Done
    LDA InAssassinateRange         
    BEQ ReadA_Done                 ; if not in assassination range branch to ReadA_Done 
    LDA on_top_wall
    BNE ReadA_Done                 ; if on top of a wall branch to ReadA_Done
    LDA #1
    STA assassinate                ; Set assassinate to true 
    LDA #0                         ; Set player speed to zero
    STA player_jump_speed          ;  (both bytes)
    STA player_jump_speed+1

ReadA_Done:

;----------- B BUTTON--------;

    LDA joypad1_state
    AND #BUTTON_B
    BEQ ReadB_Done                 ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button
    ; Spawn a arrow
    LDA arrow_active
    BNE ReadB_Done                 ; check if arrow is active (checks if arrow_active is not equal to 0)
    ; No arrow active, so spawn a new one
    SpawnArrow

ReadB_Done:
    RTS    ; End subroutine 

;----------------------- UPDATE ARROW--------------------;
UpdateArrow: ; Begin subroutine
; Update the arrow
    LDA arrow_active
    ; Check if arrow is active              
    BEQ UpdateArrow_Done
    ; Check arrow shoot direction, right(0) left (1)
    LDA arrow_direction
    BEQ ShootRight
    ; Shoot arrow LEFT
    LDA sprite_arrow + SPRITE_X
    SEC
    SBC #ARROW_SPEED
    STA sprite_arrow + SPRITE_X
    BCS UpdateArrow_Done
    ; If carry flag is clear, arrow has left the top of the screen -- destroy it
    JMP DestroyArrow
ShootRight:
    ; Shoot arrow RIGHT
    LDA sprite_arrow + SPRITE_X
    CLC 
    ADC #ARROW_SPEED
    STA sprite_arrow + SPRITE_X    
    BCC UpdateArrow_Done
DestroyArrow
    ; If carry flag is set, arrow has left the top of the screen -- destroy it
    LDA #0
    STA arrow_active
    LDA next_arrow_direction
    STA arrow_direction

UpdateArrow_Done:
    RTS    ; End subroutine 

;----------------------- UPDATE PLAYER--------------------;
UpdatePlayer: ; Begin subroutine
    ; Check if player is assassinating
    LDA assassinate
    BEQ NotAssassinating
    ; Moves player straight to enemy and kills the enemy
    assassinateEnemy 
NotAssassinating:
    ; First, update speed
    LDA player_jump_speed      ; Low 8 bits
    CLC
    ADC #LOW(GRAVITY)
    STA player_jump_speed
    LDA player_jump_speed+1    ; High 8 bits
    ADC #HIGH(GRAVITY)         ; NB: *don't* clear the carry flag!
    STA player_jump_speed+1
UpdatePlayerPosition:
    ; Second, update position
    LDA player_position_sub    ; Low 8 bits
    CLC
    ADC player_jump_speed
    STA player_position_sub
    LDA sprite_player+SPRITE_Y ; High 8 bits
    ADC player_jump_speed+1    ; NB: *don't* clear the carry flag!
    STA sprite_player+SPRITE_Y

    ; Check for the bottom of screen
    CMP screen_bottom          ; Accumulator
    BCC UpdatePlayer_NoClamp
    LDA screen_bottom;
    SEC
    SBC #1
    STA sprite_player+SPRITE_Y
    LDA #0                     ; Set player speed to zero
    STA player_jump_speed      ; (both bytes)
    STA player_jump_speed+1
UpdatePlayer_NoClamp:
    RTS    ; End subroutine

;----------- CHECK ASSASSINATION RANGE--------;
CheckAssassinationRange: ; Begin subroutine
    ; Check if player in assassinate range
    LDA sprite_player+SPRITE_X
    CLC
    ADC #ASSINATE_RANGE
    CMP sprite_enemy+SPRITE_X      ; if playerX + 10 >= enemyX next range check
    BCC NotInRange
    SEC
    SBC #ENEMY_HITBOX_WIDTH + ASSINATE_RANGE*2 
    CMP sprite_enemy+SPRITE_X      ; if playerX - enemyW - 10 >= enemyX next range check
    BCS NotInRange
    LDA sprite_enemy+SPRITE_Y
    CMP sprite_player+SPRITE_Y     ; if enemyY >= playerY set assassinate to true, else branch to NotInRange
    BCC NotInRange
    LDA #1
    STA InAssassinateRange         ; Set InAssassinateRange to true
    LDA #2
    STA sprite_enemy+SPRITE_ATTRIB ; Set enemy attributes (change it's colour to show player that they are in range)
    JMP AssassinateRangeCheck_Done
NotInRange:
    LDA InAssassinateRange
    BEQ AssassinateRangeCheck_Done
    LDA #0
    STA InAssassinateRange         ; Set InAssassinateRange to true
    LDA #1
    STA sprite_enemy+SPRITE_ATTRIB ; Set enemy attributes (Reset back to normal colour when not in range)
AssassinateRangeCheck_Done:
    RTS    ; End subroutine

;--------------- WALL COLLISION CHECKS-------------;
CheckWallCollisions: ; Begin subroutine

    ; CollisionCheck parameters: scroll_x, player_y, wall_x, wall_w, wall_h, no_collision_label, on_top_label, climbing_active_direction, left(0) or right (1)
    ; RIGHT COLLISIONS
    ; -1 from wall width to allow left collisions to work
    CollisionCheck scroll_x, sprite_player+SPRITE_Y, #WALL1_X, #WALL1_W-1, #WALL1_H, NoCollision1, OnTop1, climbing_right_active, #1
NoCollision1:
    CollisionCheck scroll_x, sprite_player+SPRITE_Y, #WALL2_X, #WALL2_W-1, #WALL2_H, NoCollision2, OnTop2, climbing_right_active, #1
NoCollision2:
    ; LEFT COLLISIONS
    CollisionCheck scroll_x, sprite_player+SPRITE_Y, #WALL1_X, #WALL1_W, #WALL1_H, NoCollision3, OnTop3, climbing_left_active, #0
NoCollision3:
    CollisionCheck scroll_x, sprite_player+SPRITE_Y, #WALL2_X, #WALL2_W, #WALL2_H, NoCollision4, OnTop4, climbing_left_active, #0
NoCollision4:
    ;  Reset floor
    LDA #SCREEN_BOTTOM
    STA screen_bottom
    LDA #0
    STA on_top_wall                ; Set on_top_wall (player is on top of a wall) to true
NoClimbingActive:
    ; Set both climbing bools to false
    SetClimbingActive #0, climbing_right_active
    SetClimbingActive #0, climbing_left_active
    ;SetSpriteTile #0, sprite_player   
CollisionChecksDone:
    RTS    ; End subroutine

;----------------------- UPDATE ENEMY------------------------;
UpdateEnemy: ; Begin subroutine
    ; Check if enemy can see player
    LDA sprite_player+SPRITE_Y
    CMP #SCREEN_BOTTOM - ENEMY_Y_VISION   ; if playerX >= bottom + enemy Y vision branch to MoveEnemyTowardsPlayer
    BCS MoveEnemyTowardsPlayer
    JMP EnemyX_Updated                    ; Else EnemyX is updated 
MoveEnemyTowardsPlayer:
    ; Set ground
    LDA #SCREEN_BOTTOM
    STA sprite_enemy+SPRITE_GROUND
    LDA sprite_player+SPRITE_X
    CMP sprite_enemy+SPRITE_X             ; if playerX >= enemyX set carry flag, else clear carry flag
    BCC MoveEnemyLeft
MoveEnemyRight:
    ; Second, update position
    LDA enemyX_position_sub               ; Low 8 bits
    CLC
    ADC #LOW(ENEMY_X_SPEED)*-1
    STA enemyX_position_sub
    LDA sprite_enemy+SPRITE_X             ; High 8 bits
    ADC #HIGH(ENEMY_X_SPEED)*-1           ; NB: *don't* clear the carry flag!
    STA sprite_enemy+SPRITE_X
    JMP EnemyX_Updated
MoveEnemyLeft:
    ; Second, update position
    LDA enemyX_position_sub               ; Low 8 bits
    SEC
    SBC #LOW(ENEMY_X_SPEED)
    STA enemyX_position_sub
    LDA sprite_enemy+SPRITE_X             ; High 8 bits
    SBC #HIGH(ENEMY_X_SPEED)              ; NB: *don't* clear the carry flag!
    STA sprite_enemy+SPRITE_X
EnemyX_Updated:
    ; First, update speed
    LDA enemyY_speed                      ; Low 8 bits
    CLC
    ADC #LOW(GRAVITY)
    STA enemyY_speed
    LDA enemyY_speed+1                    ; High 8 bits
    ADC #HIGH(GRAVITY)                    ; NB: *don't* clear the carry flag!
    STA enemyY_speed+1
    ; Second, update position
    LDA enemyY_position_sub               ; Low 8 bits
    CLC
    ADC enemyY_speed
    STA enemyY_position_sub
    LDA sprite_enemy+SPRITE_Y             ; High 8 bits
    ADC enemyY_speed+1                    ; NB: *don't* clear the carry flag!
    STA sprite_enemy+SPRITE_Y
    ; Check for the bottom of screen
    CMP sprite_enemy+SPRITE_GROUND
    BCC UpdateEnemy_NoClamp
    LDA sprite_enemy+SPRITE_GROUND
    SEC
    SBC #1
    STA sprite_enemy+SPRITE_Y
    LDA #0                                ; Set player speed to zero
    STA enemyY_speed                      ; (both bytes)
    STA enemyY_speed+1
UpdateEnemy_NoClamp:
    RTS    ; End subroutine

;---------------- CHECK ENEMY COLLISIONS---------------;
CheckEnemyCollisions: ; Begin subroutine

    ; Check collision with arrow
    CheckCollisionWithEnemy sprite_arrow+SPRITE_X, sprite_arrow+SPRITE_Y, #ARROW_HITBOX_X, #ARROW_HITBOX_Y, #ARROW_HITBOX_WIDTH, #ARROW_HITBOX_HEIGHT, UpdateEnemy_NoCollision
    ; Handle collision
    LDA #0
    STA arrow_active             ; Destroy the arrow
    LDA #$FF
    STA sprite_arrow+SPRITE_X    ; Set arrowX to FF 
    ; Respawn enemy
    LDA sprite_enemy+SPRITE_X
    CLC
    ADC #ENEMY_RESPAWN
    STA sprite_enemy+SPRITE_X
    ; Add 1 to score
    IncrementScore
UpdateEnemy_NoCollision:
    ; Check collision with player
    CheckCollisionWithEnemy sprite_player+SPRITE_X, sprite_player+SPRITE_Y, #0, #0, #PLAYER_WIDTH, #PLAYER_HEIGHT, UpdateEnemy_End
    ; Handle collision
    LDA assassinate
    BEQ PlayerKilled
    ; Add 1 to score
    IncrementScore
    LDA #HIT_STOP_LENGTH    ; Load hit stop length into accumulator
    STA hit_stop_timer      ; Store in hit stop timer
    LDA #1
    STA hit_stop            ; Set hit stop to true
    JMP UpdateEnemy_End
PlayerKilled:
    ; Reset score
    LDA #0
    STA score
    LDA #$80
    STA sprite_score_num+SPRITE_TILE
    STA sprite_score_num2+SPRITE_TILE
    ; Respawn player
    LDA sprite_player+SPRITE_Y
    CLC
    ADC #PLAYER_RESPAWN
    STA sprite_player+SPRITE_Y
    ScrollBackground #0, #1, Scroll_NoWrap3, #0
UpdateEnemy_End:
    RTS    ; End subroutine

;---------------- UPDATE HITSTOP---------------;
UpdateHit_Stop:
    LDA hit_stop
    BEQ UpdateHit_Stop_End     ; If theres no hit stop active, branch to UpdateHit_Stop_End
    LDA hit_stop_timer
    BEQ HitStop_Complete
    SEC
    SBC #1                     ; Decrement hit stop timer
    STA hit_stop_timer
    JMP UpdateGame_End
HitStop_Complete:
    ; Kill enemy and respawn
    LDA #0 
    STA assassinate            ; Set assinate to false 
    STA hit_stop               ; Set hit stop to false
    ; Respawn enemy       
    LDA sprite_enemy+SPRITE_X
    CLC
    ADC #ENEMY_RESPAWN
    STA sprite_enemy+SPRITE_X
    SetSpriteTile #0, sprite_player
UpdateHit_Stop_End:     
    RTS    ; End subroutine  

;---------------- UPDATE SCORE---------------;
UpdateScore:
    LDA score
    CMP #10      ; If score >= 10 increment tens digit
    BCS IncrementTensDigit 
    CLC 
    ADC #$80     ; Add 80 because the number sprites start at tile 80
    STA sprite_score_num2+SPRITE_TILE
    JMP ScoreUpdateDone
IncrementTensDigit:
    ; Reset score to 0 (doesn't reset the actual score shown in-game)
    LDA #0
    STA score
    ; Set the second digit sprite tile (units) to 0     
    LDA #$80
    STA sprite_score_num2+SPRITE_TILE
    ; Change tens digit sprite to next number 
    LDA sprite_score_num+SPRITE_TILE
    CLC
    ADC #1
    STA sprite_score_num+SPRITE_TILE
ScoreUpdateDone:
    RTS    ; End subroutine    