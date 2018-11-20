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

NUM_ENEMIES   = 5

    .rsset $0010
joypad1_state            .rs 1
nametable_address        .rs 2
bullet_active            .rs 1
bullet_direction         .rs 1
scroll_x                 .rs 1
screen_bottom            .rs 1
climbing_right_active    .rs 1
climbing_left_active     .rs 1
scroll_page              .rs 1
player_jump_speed        .rs 2 ; in subpixels/frame -- 16bits
player_position_sub      .rs 1 ; in subpixels
enemy_info               .rs 4 * NUM_ENEMIES
enemyY_speed             .rs 2
enemyY_position_sub      .rs 1 ; in subpixels
enemyX_speed             .rs 2
enemyX_position_sub      .rs 1 ; in subpixels
     
    .rsset $0200
sprite_player      .rs 4
sprite_bullet      .rs 4
sprite_wall        .rs 4
sprite_enemy       .rs 4 * NUM_ENEMIES

    .rsset $0000
SPRITE_Y           .rs 1
SPRITE_TILE        .rs 1
SPRITE_ATTRIB      .rs 1
SPRITE_X           .rs 1

;     .rsset $0000
; ENEMY_SPEED        .rs 1
; ENEMY_ALIVE        .rs 1

ENEMY_X_SPEED       = 128     ; in subpixels/frame
GRAVITY             = 16        ; in subpixels/frame^2
JUMP_SPEED          = -2 * 256 - 64; in subpixels/frame
SCREEN_BOTTOM       = 224

PLAYER_HEIGHT       = 8
PLAYER_X_OFFSET     = 6

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

    ; Write sprite data for sprite 0
    LDA #120    ; Y pos
    STA sprite_player + SPRITE_Y
    LDA #0      ; Tile No.
    STA sprite_player + SPRITE_TILE
    LDA #0   ; Attributes (different palettes?)
    STA sprite_player + SPRITE_ATTRIB
    LDA #128    ; X pos
    STA sprite_player + SPRITE_X

    ; Write sprite data for sprite 0
    LDA #135    ; Y pos
    STA sprite_enemy + SPRITE_Y
    LDA #$05      ; Tile No.
    STA sprite_enemy + SPRITE_TILE
    LDA #1   ; Attributes (different palettes?)
    STA sprite_enemy + SPRITE_ATTRIB
    LDA #60    ; X pos
    STA sprite_enemy + SPRITE_X


    ; Load nametable data 
    LDA #$20        ; Write address $2000 to PPUADDR register
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
    LDA #$23        ; Write address $23C0 to PPUADDR register
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
    LDA #SCREEN_BOTTOM                             ; Calculate screen_bottom - wall_h
    SEC
    SBC \5 - PLAYER_HEIGHT
    CMP \2                                         ; If Screen_botttom - wall_h - Player_height >= player_y then player is on top of wall
    BCS \7                                         ; Branch to the on_top_label 
    .endm

SetCollisionActive .macro ; params: collision_active (left or right)
    LDA #1
    STA \1
    .endm

SetBottom .macro    ; params: wall_h
    LDA #(SCREEN_BOTTOM + PLAYER_HEIGHT - \1)       ; Load in SCREEN BOTTOM + PLAYER HEIGHT - WALL HEIGHT 
    STA screen_bottom
    JMP NoClimbingActive
    .endm

Climb .macro
    LDA sprite_player + SPRITE_Y                    ; Load player Y into accumulator
    SEC 
    SBC #1                                          ; Minus 1 from player Y
    STA sprite_player + SPRITE_Y                    ; Store value back into player Y
    ; Stop playing from falling from gravity (or moving up from jumping)
    ResetPlayerSpeed
    .endm

ResetPlayerSpeed .macro 
    LDA #0                                          ; Load 0 into accumulator
    STA player_jump_speed                                ; Store into player_jump_speed and player_jump_speed+1
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

ScrollBackground .macro  ; params: Left(0) or Right(1), no_scroll_label
    LDA scroll_x
    .if \1 < 1                                      ; If direction is 0 scroll left, else scroll right 
    SEC
    SBC #1
    .else
    CLC 
    ADC #1
    .endif
    STA scroll_x
    STA PPUSCROLL
    LDA sprite_enemy+SPRITE_X
    .if \1 < 1                                      ; If direction is 0 scroll left, else scroll right 
    CLC
    ADC #1
    .else
    LDA sprite_enemy+SPRITE_X
    SEC
    SBC #1
    .endif
    STA sprite_enemy+SPRITE_X
    BCC \2
    ; scroll_x has wrapped, so switch scroll_page
    LDA scroll_page
    EOR #1
    STA scroll_page
    ORA #%10000000
    STA PPUCTRL
    
    .endm

CollisionCheck .macro
    CheckCollisionWithWall \1, \2, \3, \4, \5, \6, \7
    SetCollisionActive \8
    JMP CollisionChecksDone
\7:
    SetBottom \5
    .endm 


    ; CollisionCheck parameters: scroll_x, player_y, wall_x, wall_w, wall_h, no_collision_label, on_top_label, climbing_active_direction
    ; RIGHT COLLISIONS
    ; -1 from wall width to allow left collisions to work
    CollisionCheck scroll_x, sprite_player+SPRITE_Y, #WALL1_X, #WALL1_W-1, #WALL1_H, NoCollision1, OnTop1, climbing_right_active
NoCollision1:
    CollisionCheck scroll_x, sprite_player+SPRITE_Y, #WALL2_X, #WALL2_W-1, #WALL2_H, NoCollision2, OnTop2, climbing_right_active
NoCollision2:
    ; LEFT COLLISIONS
    CollisionCheck scroll_x, sprite_player+SPRITE_Y, #WALL1_X, #WALL1_W, #WALL1_H, NoCollision3, OnTop3, climbing_left_active
NoCollision3:
    CollisionCheck scroll_x, sprite_player+SPRITE_Y, #WALL2_X, #WALL2_W, #WALL2_H, NoCollision4, OnTop4, climbing_left_active
NoCollision4:
    ;  Reset floor
    LDA #224
    STA screen_bottom
NoClimbingActive:
    LDA #0
    STA climbing_right_active
    LDA #0
    STA climbing_left_active    
CollisionChecksDone:

    ; Initialise controller 1
    LDA #1
    STA JOY1
    LDA #0
    STA JOY1

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

    ; React to Right button
    LDA joypad1_state
    AND #BUTTON_RIGHT
    BEQ ReadRight_Done ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button
    LDA climbing_right_active
    BEQ NoWallCollision
    ; Stop jump by reseting speed 
    ResetPlayerSpeed
    ; Call climb macro
    Climb
    JMP ReadRight_Done
NoWallCollision:
    ; Call scroll background macro
    ScrollBackground #1, Scroll_NoWrap
Scroll_NoWrap:
    LDA #0
    STA PPUSCROLL
    ; Check if player is on a left wall
    LDA climbing_left_active   
    BNE WallJumpRight           ; If player is on a left wall, branch to WallJumpRight
    JMP ReadRight_Done
WallJumpRight:
    PlayerJump
ReadRight_Done:
     ; Read Down button
    LDA joypad1_state
    AND #BUTTON_DOWN
    BEQ ReadDown_Done ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button

ReadDown_Done:
    ; React to Left button
    LDA joypad1_state
    AND #BUTTON_LEFT
    BEQ ReadLeft_Done ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button 
    ; If Colliding 
    LDA climbing_left_active
    BEQ NoWallCollision2
    ; Stop jump by reseting speed 
    ResetPlayerSpeed
    ; Call climb macro
    Climb
    JMP ReadLeft_Done

NoWallCollision2:
    ; Call scroll background macro
    ScrollBackground #0, Scroll_NoWrap2
Scroll_NoWrap2:
    LDA #0
    STA PPUSCROLL
    ; Check if player is on right wall
    LDA climbing_right_active   
    BNE WallJumpLeft           ; If player is on a right wall, branch to WallJumpLeft
    JMP ReadLeft_Done
WallJumpLeft:
    PlayerJump
    
ReadLeft_Done:

     ; Read Up button
    LDA joypad1_state
    AND #BUTTON_UP
    BEQ ReadUp_Done ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button

    ; Check if player is on ground
    LDA screen_bottom ;#SCREEN_BOTTOM_Y - 2    ; Load ScreenBottom into accumulator
    SEC
    SBC #2
    CLC                         ; clear carry flag
    CMP sprite_player+SPRITE_Y  ; if ScreenBottom >= PlayerY set carry flag
    BCS ReadUp_Done
    PlayerJump

ReadUp_Done:

; React to A button

    LDA joypad1_state
    AND #BUTTON_A
    BEQ ReadA_Done ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button
    ; Spawn a bullet
    LDA bullet_active
    BNE ReadA_Done    ; check if bullet is active (checks if bullet_active is not equal to 0)
    ; No bullet active, so spawn a new one
    LDA #1
    STA bullet_active
    LDA #0
    STA bullet_direction
    LDA sprite_player + SPRITE_Y   ; Y pos
    STA sprite_bullet + SPRITE_Y
    LDA #2      ; Tile No.
    STA sprite_bullet + SPRITE_TILE
    LDA #0      ; Attributes (different palettes?)
    STA sprite_bullet + SPRITE_ATTRIB
    LDA sprite_player + SPRITE_X   ; X pos
    STA sprite_bullet + SPRITE_X

ReadA_Done:

; React to B button

    LDA joypad1_state
    AND #BUTTON_B
    BEQ ReadB_Done ; if ((JOY1 & 1)) != 0 execution continues, else branch to next button
    ; Spawn a bullet
    LDA bullet_active
    BNE ReadB_Done    ; check if bullet is active (checks if bullet_active is not equal to 0)
    ; No bullet active, so spawn a new one
    LDA #1
    STA bullet_active
    STA bullet_direction
    LDA sprite_player + SPRITE_Y   ; Y pos
    STA sprite_bullet + SPRITE_Y
    LDA #2      ; Tile No.
    STA sprite_bullet + SPRITE_TILE
    LDA #0      ; Attributes 
    STA sprite_bullet + SPRITE_ATTRIB
    LDA sprite_player + SPRITE_X   ; X pos
    STA sprite_bullet + SPRITE_X
    ; Flip the sprite
    LDA sprite_bullet+SPRITE_ATTRIB
    EOR #%01000000
    STA sprite_bullet+SPRITE_ATTRIB

ReadB_Done:

; Update the bullet
    LDA bullet_active
    BEQ UpdateBullet_Done
    LDA bullet_direction
    BEQ ShootRight
    LDA sprite_bullet + SPRITE_X
    SEC
    SBC #4
    STA sprite_bullet + SPRITE_X
    BCS UpdateBullet_Done
    ; If carry flag is clear, bullet has left the top of the screen -- destroy it
    LDA #0
    STA bullet_active
    JMP UpdateBullet_Done
ShootRight:
    LDA sprite_bullet + SPRITE_X
    CLC 
    ADC #4
    STA sprite_bullet + SPRITE_X    
    BCC UpdateBullet_Done
    ; If carry flag is clear, bullet has left the top of the screen -- destroy it
    LDA #0
    STA bullet_active

UpdateBullet_Done:
    ; Update player sprite
    ; First, update speed
    LDA player_jump_speed    ; Low 8 bits
    CLC
    ADC #LOW(GRAVITY)
    STA player_jump_speed
    LDA player_jump_speed+1  ; High 8 bits
    ADC #HIGH(GRAVITY)  ; NB: *don't* clear the carry flag!
    STA player_jump_speed+1

    ; Second, update position
    LDA player_position_sub    ; Low 8 bits
    CLC
    ADC player_jump_speed
    STA player_position_sub
    LDA sprite_player+SPRITE_Y ; High 8 bits
    ADC player_jump_speed+1         ; NB: *don't* clear the carry flag!
    STA sprite_player+SPRITE_Y

    ; Check for the bottom of screen
    CMP screen_bottom ;#SCREEN_BOTTOM_Y    ; Accumulator
    BCC UpdatePlayer_NoClamp
    LDA screen_bottom;#SCREEN_BOTTOM_Y-1
    SEC
    SBC #1
    STA sprite_player+SPRITE_Y
    LDA #0                  ; Set player speed to zero
    STA player_jump_speed        ; (both bytes)
    STA player_jump_speed+1
UpdatePlayer_NoClamp:

; Update enemies
    LDA sprite_player+SPRITE_X
    CMP sprite_enemy+SPRITE_X   ; if playerX >= enemyX set carry flag, else clear carry flag
    BCC MoveEnemyLeft
MoveEnemyRight:
    ; Second, update position
    LDA enemyX_position_sub    ; Low 8 bits
    CLC
    ADC #LOW(ENEMY_X_SPEED)*-1
    STA enemyX_position_sub
    LDA sprite_enemy+SPRITE_X ; High 8 bits
    ADC #HIGH(ENEMY_X_SPEED)*-1         ; NB: *don't* clear the carry flag!
    STA sprite_enemy+SPRITE_X
    JMP EnemyX_Updated
MoveEnemyLeft:
    ; Second, update position
    LDA enemyX_position_sub    ; Low 8 bits
    SEC
    SBC #LOW(ENEMY_X_SPEED)
    STA enemyX_position_sub
    LDA sprite_enemy+SPRITE_X ; High 8 bits
    SBC #HIGH(ENEMY_X_SPEED)         ; NB: *don't* clear the carry flag!
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
    ADC enemyY_speed+1         ; NB: *don't* clear the carry flag!
    STA sprite_enemy+SPRITE_Y

    ; Check for the bottom of screen
    CMP screen_bottom ;#SCREEN_BOTTOM_Y    ; Accumulator
    BCC UpdateEnemy_NoClamp
    LDA screen_bottom;#SCREEN_BOTTOM_Y-1
    SEC
    SBC #1
    STA sprite_enemy+SPRITE_Y
    LDA #0                  ; Set player speed to zero
    STA enemyY_speed        ; (both bytes)
    STA enemyY_speed+1
UpdateEnemy_NoClamp:



    ; copy sprite data to ppu
    LDA #0
    STA OAMADDR 
    LDA #$02
    STA OAMDMA

    RTI         ; Return from interrupt

; ---------------------------------------------------------------------------

NametableData:
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$40,$41,$42,$43,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$50,$51,$52,$53,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$60,$61,$62,$63,$03,$03,$03  
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$70,$71,$72,$73,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03  
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
    .db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$10,$11,$12,$13,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$20,$21,$22,$23,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$10,$11,$12,$13,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 
    .db $03,$03,$03,$03,$03,$03,$20,$21,$22,$23,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03  
    .db $03,$03,$03,$03,$03,$03,$10,$11,$12,$13,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$10,$11,$12,$13,$10,$11,$12,$13,$03,$03,$03,$03 
    .db $0B,$03,$03,$03,$03,$03,$20,$21,$22,$23,$03,$29,$2A,$2B,$2C,$2D,$2E,$2F,$03,$03,$20,$21,$22,$23,$20,$21,$22,$23,$03,$03,$09,$0A 
    .db $1B,$1C,$1D,$03,$03,$03,$10,$11,$12,$13,$03,$39,$3A,$3B,$3C,$3D,$3E,$3F,$03,$03,$10,$11,$12,$13,$10,$11,$12,$13,$03,$03,$19,$1A
    .db $08,$08,$08,$08,$08,$08,$20,$21,$22,$23,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$20,$21,$22,$23,$20,$21,$22,$23,$08,$08,$08,$08 
    .db $08,$08,$08,$08,$08,$08,$10,$11,$12,$13,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$10,$11,$12,$13,$10,$11,$12,$13,$08,$08,$08,$08 
    .db $08,$08,$08,$08,$08,$08,$20,$21,$22,$23,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$20,$21,$22,$23,$20,$21,$22,$23,$08,$08,$08,$08 
    .db $08,$08,$08,$08,$08,$08,$10,$11,$12,$13,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$10,$11,$12,$13,$10,$11,$12,$13,$08,$08,$08,$08 
    .db $08,$08,$08,$08,$08,$08,$20,$21,$22,$23,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$20,$21,$22,$23,$20,$21,$22,$23,$08,$08,$08,$08
    .db $00 ; null terminator

; ---------------------------------------------------------------------------

    .bank 1
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0

; ---------------------------------------------------------------------------

    .bank 2
    .org $0000
    .incbin "Robot.chr"