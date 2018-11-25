    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1

; ---------------------------------------------------------------------------

PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
OAMDATA   = $2004
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
OAMDMA    = $4014
JOY1      = $4016
JOY2      = $4017

BUTTON_A      = %10000000
BUTTON_B      = %01000000
BUTTON_SELECT = %00100000
BUTTON_START  = %00010000
BUTTON_UP     = %00001000
BUTTON_DOWN   = %00000100
BUTTON_LEFT   = %00000010
BUTTON_RIGHT  = %00000001

    .rsset $0010
joypad1_state            .rs 1  
nametable_address        .rs 2
arrow_active             .rs 1      ; arrow active bool
arrow_direction          .rs 1      ; direction of arrow: left(0) right(1)
scroll_x                 .rs 1      ; scroll value
screen_bottom            .rs 1      ; ground
climbing_right_active    .rs 1      ; climbing right bool
climbing_left_active     .rs 1      ; climbing left bool
scroll_page              .rs 1      ; scroll page
player_jump_speed        .rs 2      ; in subpixels/frame -- 16bits
player_position_sub      .rs 1      ; in subpixels
enemyY_speed             .rs 2      ; in subpixels/frame -- 16bits 
enemyY_position_sub      .rs 1      ; in subpixels
enemyX_speed             .rs 2      ; in subpixels/frame -- 16bits
enemyX_position_sub      .rs 1      ; in subpixels
assassinate              .rs 1      ; Is player assassinating bool
hit_stop_timer           .rs 1      ; hit stop timer
hit_stop                 .rs 1      ; hit stop bool
InAssassinateRange       .rs 1      ; Is in assassination range bool
player_anim_state        .rs 1      ; Player animation state
next_arrow_direction     .rs 1      ; next arrow direction
score                    .rs 1      ; Player score, + 1 for each kill
on_top_wall              .rs 1      ; Is player on top of a wall  

    .rsset $0200
sprite_player      .rs 4            ; player sprite
sprite_arrow      .rs 4             ; ARROW sprite
; Score text sprites
sprite_score1      .rs 4            ; S  
sprite_score2      .rs 4            ; C
sprite_score3      .rs 4            ; O
sprite_score4      .rs 4            ; R
sprite_score5      .rs 4            ; E
sprite_score_num   .rs 4            ; 0
sprite_score_num2  .rs 4            ; 0
sprite_enemy       .rs 4            ; enemy sprite

    .rsset $0000
SPRITE_Y           .rs 1            ; sprite Y position
SPRITE_TILE        .rs 1            ; sprite tile number
SPRITE_ATTRIB      .rs 1            ; sprite attributes
SPRITE_X           .rs 1            ; sprite X position
SPRITE_GROUND      .rs 1            ; sprite ground position

; Player constants
PLAYER_WIDTH        = 4
PLAYER_HEIGHT       = 8
PLAYER_X_OFFSET     = 6 
PLAYER_RESPAWN      = 100
ASSASSIN_FALL_SPEED = 64            ; player acceleration when assassinating, in subpixels/frame^2
ASSINATE_RANGE      = 30            ; X range for assassinating
JUMP_SPEED          = -2 * 256 - 64 ; in subpixels/frame

; Enemy constants
ENEMY_RESPAWN       = 100
ENEMY_X_SPEED       = 128           ; in subpixels/frame
ENEMY_Y_VISION      = 50            ; Y range for enemy vision
ENEMY_SQUAD_WIDTH    = 6
ENEMY_SQUAD_HEIGHT   = 4
ENEMY_HITBOX_WIDTH   = 4
ENEMY_HITBOX_HEIGHT  = 4

; Other constants
GRAVITY             = 16            ; in subpixels/frame^2
SCREEN_BOTTOM       = 224           ; Screen bottom Y value
HIT_STOP_LENGTH     = 10             ; Number of frames to pause game for when hitting an enemy

; Arrow constants
ARROW_HITBOX_X      = 3            ; Relative to sprite top left corner
ARROW_HITBOX_Y      = 1
ARROW_HITBOX_WIDTH  = 2
ARROW_HITBOX_HEIGHT = 6
ARROW_SPEED         = 3

; Wall properties
; Add scroll_x to the X value to move the collision of the walls as the background scrolls
WALL1_X       = (scroll_x+5)            
WALL1_Y       = 64                  
WALL1_W       = 64                  
WALL1_H       = 64                  
WALL2_X       = (scroll_x-107)      
WALL2_Y       = 64                  
WALL2_W       = 32                  
WALL2_H       = 96                  

    .bank 0
    .org $C000

; Initialisation code based on https://wiki.nesdev.com/w/index.php/Init_code
RESET:
    SEI        ; ignore IRQs
    CLD        ; disable decimal mode
    LDX #$40
    STX $4017  ; disable APU frame IRQ
    LDX #$ff
    TXS        ; Set up stack
    INX        ; now X = 0
    STX PPUCTRL  ; disable NMI
    STX PPUMASK  ; disable rendering
    STX $4010  ; disable DMC IRQs

    ; Optional (omitted):
    ; Set up mapper and jmp to further init code here.

    ; If the user presses Reset during vblank, the PPU may reset
    ; with the vblank flag still true.  This has about a 1 in 13
    ; chance of happening on NTSC or 2 in 9 on PAL.  Clear the
    ; flag now so the vblankwait1 loop sees an actual vblank.
    BIT PPUSTATUS

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
vblankwait1:  
    BIT PPUSTATUS
    BPL vblankwait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    TXA
clrmem:
    LDA #0
    STA $000,x
    STA $100,x
    STA $300,x
    STA $400,x
    STA $500,x
    STA $600,x
    STA $700,x  ; Remove this if you're storing reset-persistent data

    ; We skipped $200,x on purpose.  Usually, RAM page 2 is used for the
    ; display list to be copied to OAM.  OAM needs to be initialized to
    ; $EF-$FF, not 0, or you'll get a bunch of garbage sprites at (0, 0).

    LDA #$FF
    STA $200,x

    INX
    BNE clrmem

    ; Other things you can do between vblank waits are set up audio
    ; or set up other mapper registers.
   
vblankwait2:
    BIT PPUSTATUS
    BPL vblankwait2

    ; End of initialisation code

    JSR InitialiseGame

    LDA #%10000000 ; Enable NMI
    STA PPUCTRL

    LDA #%00011000 ; Enable sprites and background
    STA PPUMASK

    LDA #0
    STA PPUSCROLL  ; Set x scroll
    STA PPUSCROLL  ; Set y scroll

    ; Enter an infinite loop
forever:
    JMP forever

; ------------------------------------------------------

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
    

    RTS ; End subroutine
; ----------------------------------------------------------------------------

; NMI is called on every frame
NMI:

    LDA hit_stop
    BEQ NoHit_Stop
    JMP UpdateHit_Stop
NoHit_Stop:

    ; Include macros
    INCLUDE "macros.asm"

;----------- WALL COLLISION CHECKS--------;

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
    LDA #224
    STA screen_bottom
    LDA #0
    STA on_top_wall           ; Set on_top_wall (player is on top of a wall) to true
NoClimbingActive:
    ; Set both climbing bools to false
    SetClimbingActive #0, climbing_right_active
    SetClimbingActive #0, climbing_left_active
    ;SetSpriteTile #0, sprite_player   
CollisionChecksDone:

;----------- CHECK ASSASSINATION RANGE--------;
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

;----------- READ JOYPAD--------;

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
    BEQ ReadRightDone_JUMP             ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button
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
    BNE SetNextArrowDirection     ; If arrow is active, set next arrow direction so it doesn't affect the current active arrow 
    LDA #0
    STA arrow_direction           ; If arrow is not active, set the arrow direction to right
    JMP UpdateSpriteTile
SetNextArrowDirection:
    LDA #0
    STA next_arrow_direction      ; Set next arrow direction to right
UpdateSpriteTile:
    ; Update sprite tile (ANIMATION)
    LDA player_anim_state
    BEQ ZeroState                 ; If anim state is 0 branch to ZeroState
    ; Accumulator is 1
    STA sprite_player+SPRITE_TILE ; Else set the sprite tile to tile 01 (state 1 right)
    LDA #0
    STA player_anim_state         ; Switch anim state
    JMP SpriteTile_Updated
ZeroState:
    ; Accumulator is 0
    STA sprite_player+SPRITE_TILE ; Set the sprite tile to tile 00 (state 0 right)
    LDA #1
    STA player_anim_state         ; Switch anim state
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
    BEQ ReadLeftDone_JUMP              ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button 
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
    BNE WallJumpLeft               ; If player is climbing a right wall, branch to WallJumpLeft
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
    LDA assassinate
    BEQ NotAssassinating
    ; Moves player straight to enemy and kills the enemy
    assassinateEnemy 

NotAssassinating:

;----------- UPDATE PLAYER--------;

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

;----------- UPDATE ENEMY--------;

    ; Check if enemy can see player
    LDA sprite_player+SPRITE_Y
    CMP #SCREEN_BOTTOM - ENEMY_Y_VISION   ; if playerX >= bottom+ enemy Y vision set carry
    BCS MoveEnemyTowardsPlayer
    JMP EnemyX_Updated
MoveEnemyTowardsPlayer:
    ; Set ground
    LDA #SCREEN_BOTTOM
    STA sprite_enemy+SPRITE_GROUND
    LDA sprite_player+SPRITE_X
    CMP sprite_enemy+SPRITE_X     ; if playerX >= enemyX set carry flag, else clear carry flag
    BCC MoveEnemyLeft
MoveEnemyRight:
    ; Second, update position
    LDA enemyX_position_sub       ; Low 8 bits
    CLC
    ADC #LOW(ENEMY_X_SPEED)*-1
    STA enemyX_position_sub
    LDA sprite_enemy+SPRITE_X     ; High 8 bits
    ADC #HIGH(ENEMY_X_SPEED)*-1   ; NB: *don't* clear the carry flag!
    STA sprite_enemy+SPRITE_X
    JMP EnemyX_Updated
MoveEnemyLeft:
    ; Second, update position
    LDA enemyX_position_sub    ; Low 8 bits
    SEC
    SBC #LOW(ENEMY_X_SPEED)
    STA enemyX_position_sub
    LDA sprite_enemy+SPRITE_X ; High 8 bits
    SBC #HIGH(ENEMY_X_SPEED)  ; NB: *don't* clear the carry flag!
    STA sprite_enemy+SPRITE_X
EnemyX_Updated:
    ; First, update speed
    LDA enemyY_speed    ; Low 8 bits
    CLC
    ADC #LOW(GRAVITY)
    STA enemyY_speed
    LDA enemyY_speed+1  ; High 8 bits
    ADC #HIGH(GRAVITY)  ; NB: *don't* clear the carry flag!
    STA enemyY_speed+1

    ; Second, update position
    LDA enemyY_position_sub    ; Low 8 bits
    CLC
    ADC enemyY_speed
    STA enemyY_position_sub
    LDA sprite_enemy+SPRITE_Y ; High 8 bits
    ADC enemyY_speed+1        ; NB: *don't* clear the carry flag!
    STA sprite_enemy+SPRITE_Y

    ; Check for the bottom of screen
    CMP sprite_enemy+SPRITE_GROUND
    BCC UpdateEnemy_NoClamp
    LDA sprite_enemy+SPRITE_GROUND
    SEC
    SBC #1
    STA sprite_enemy+SPRITE_Y
    LDA #0                  ; Set player speed to zero
    STA enemyY_speed        ; (both bytes)
    STA enemyY_speed+1
UpdateEnemy_NoClamp:

;----------- ENEMY COLLISIONS--------;

    ; Check collision with arrow
    CheckCollisionWithEnemy sprite_arrow+SPRITE_X, sprite_arrow+SPRITE_Y, #ARROW_HITBOX_X, #ARROW_HITBOX_Y, #ARROW_HITBOX_WIDTH, #ARROW_HITBOX_HEIGHT, UpdateEnemies_NoCollision
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
UpdateEnemies_NoCollision:
    ; Check collision with arrow
    CheckCollisionWithEnemy sprite_player+SPRITE_X, sprite_player+SPRITE_Y, #0, #0, #PLAYER_WIDTH, #PLAYER_HEIGHT, JumpToNoCollisionLabel
    ; Handle collision
    LDA assassinate
    BEQ PlayerKilled
    ; Add 1 to score
    IncrementScore
    LDA #HIT_STOP_LENGTH    ; Load hit stop length into accumulator
    STA hit_stop_timer      ; Store in hit stop timer
    LDA #1
    STA hit_stop            ; Set hit stop to true
    JMP UpdateHit_Stop
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
JumpToNoCollisionLabel:
    JMP UpdateEnemies_NoCollisionWithPlayer

    ; Hit stop to provide better feeling of impact on assassination
UpdateHit_Stop:
    LDA hit_stop_timer
    BEQ HitStop_Complete
    SEC
    SBC #1                     ; Decrement hit stop timer
    STA hit_stop_timer
    JMP UpdateEnemies_End
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
UpdateEnemies_NoCollisionWithPlayer:
    
UpdateEnemies_End:

;----------- UPDATE SCORE--------;

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
    

    ; copy sprite data to ppu
    LDA #0
    STA OAMADDR 
    LDA #$02
    STA OAMDMA

    RTI         ; Return from interrupt

; ---------------------------------------------------------------------------

    INCLUDE "nametable.asm"

; ---------------------------------------------------------------------------

    .bank 1
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0

; ---------------------------------------------------------------------------

    .bank 2
    .org $0000
    .incbin "Sprites.chr"