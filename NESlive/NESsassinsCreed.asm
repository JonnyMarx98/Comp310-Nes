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
    ; Include macros
    INCLUDE "macros.asm" 

    LDA hit_stop
    BEQ NoHit_Stop
    JSR UpdateHit_Stop
    JMP UpdateGame_End
NoHit_Stop:
    ; Check if player is colliding with the walls 
    JSR CheckWallCollisions
    ; Check if the player is in assassination range
    JSR CheckAssassinationRange
    ; Read joypad buttons
    JSR ReadJoypad
    ; Update arrow, player, and enemy
    JSR UpdateArrow 
    JSR UpdatePlayer
    JSR UpdateEnemy
    ; Check if bullet or player is colliding with enemy 
    JSR CheckEnemyCollisions
    ; Update score
    JSR UpdateScore
UpdateGame_End:  

    ; copy sprite data to ppu
    LDA #0
    STA OAMADDR 
    LDA #$02
    STA OAMDMA

    RTI         ; Return from interrupt

; ---------------------------------------------------------------------------

    INCLUDE "nametable.asm"
    INCLUDE "subroutines.asm" 

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