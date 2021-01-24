SettablesCount = $5

MenuReset:
    jsr DrawMenu
    rts

DrawMenu:
    ldy #(SettablesCount-1)
    sty $10
@KeepDrawing:
    jsr DrawSelectedValueJE
    ldy $10
    dey
    sty $10
    bpl @KeepDrawing
    rts

MenuNMI:
    jsr DrawSelectionMarkers
    lda PressedButtons
    clc
    cmp #0
    bne @READINPUT
    rts
@READINPUT:
    and #%00001111
    beq @SELECT
    ldy MenuSelectedItem
    jsr UpdateSelectedValueJE
    jmp RenderMenu
@SELECT:
    lda PressedButtons
    cmp #%00100000
    bne @START
    ldx #0
    stx MenuSelectedSubitem
    inc MenuSelectedItem
    lda MenuSelectedItem
    cmp #SettablesCount
    bne @SELECT2
    stx MenuSelectedItem
@SELECT2:
    jmp RenderMenu
@START:
    cmp #%00010000
    bne @DONE
    ldx HeldButtons
    cpx #%10000000
    lda #0
    bcc @START2
    lda #1
@START2:
    sta PrimaryHardMode
    jmp TStartGame
@DONE:
    rts
RenderMenu:
    ldy MenuSelectedItem
    jsr DrawMenu
    rts

DrawSelectionMarkers:
    ; set y position
    lda #$1E
    ldy MenuSelectedItem
@Increment:
    clc
    adc #$10
    dey
    bpl @Increment
    sta Sprite_Y_Position + (1 * SpriteLen)
    sta Sprite_Y_Position + (2 * SpriteLen)
    ; set x position
    lda #$A9
    sta Sprite_X_Position + (1 * SpriteLen)
    sbc #$8
    ldy MenuSelectedSubitem
@Decrement:
    clc
    sbc #$7
    dey
    bpl @Decrement
    sta Sprite_X_Position + (2 * SpriteLen)
    lda #$00
    sta Sprite_Attributes + (1 * SpriteLen)
    lda #$21
    sta Sprite_Attributes + (2 * SpriteLen)

    lda #$2E ; main selection sprite
    sta Sprite_Tilenumber + (1 * SpriteLen)
    lda #$27 ; sub selection sprite
    sta Sprite_Tilenumber + (2 * SpriteLen)
    rts

UpdateSelectedValueJE:
    tya
    jsr JumpEngine
    .word UpdateValueWorldNumber ; world
    .word UpdateValueLevelNumber ; level
    .word UpdateValuePUps        ; p-up
    .word UpdateValueTimer       ; timer
    .word UpdateValueFramerule   ; framerule

DrawSelectedValueJE:
    tya
    jsr JumpEngine
    .word DrawValueNormal          ; world
    .word DrawValueNormal          ; level
    .word DrawValueString_PUp          ; p-up
    .word DrawValueString_Timer    ; timer
    .word DrawValueFramerule       ; framerule

UpdateValueWorldNumber:
    ldx #$FF
    lda HeldButtons
    and #%10000000
    bne @Skip
    jsr BANK_LoadWorldCount
    ldx WorldNumber
    @Skip:
    stx $0
    ldy #0
    sty Settables+1 ; clear level counter
    jmp UpdateValueShared

UpdateValueLevelNumber:
    ldx #$FF
    lda HeldButtons
    and #%10000000
    bne @Skip
    ldx #4
    @Skip:
    stx $0
    ldy #1
    jmp UpdateValueShared

UpdateValuePUps:
    lda #6
    sta $0
    jmp UpdateValueShared

UpdateValueTimer:
    lda #2
    sta $0
    jmp UpdateValueShared

UpdateValueShared:
    clc
    lda PressedButtons
    and #%000110
    bne @Decrement
@Increment:
    lda Settables, y
    adc #1
    cmp $0
    bcc @Store
    lda #0
    bvc @Store
@Decrement:
    lda Settables, y
    beq @Wrap
    sbc #0
    bvc @Store
@Wrap:
    lda $0
    sbc #0
@Store:
    sta Settables, y
    rts

PUpStrings:
.word PUpStrings_Non
.word PUpStrings_Spr
.word PUpStrings_Fir
.word PUpStrings_SNon
.word PUpStrings_SSpr
.word PUpStrings_SFir
PUpStrings_Non:
.byte "NONE "
PUpStrings_Spr:
.byte "SUPR "
PUpStrings_Fir:
.byte "FIRE "
PUpStrings_SNon:
.byte "NONE!"
PUpStrings_SSpr:
.byte "SUPR!"
PUpStrings_SFir:
.byte "FIRE!"

DrawValueString_PUp:
    lda Settables,y
    asl a
    tax
    lda PUpStrings,x
    sta $C0
    lda PUpStrings+1,x
    sta $C1
    lda #5
    sta $C2
    jmp DrawValueString

TimerStrings:
.word TimerStrings_Fast
.word TimerStrings_Slow
TimerStrings_Fast:
.byte "FAST"
TimerStrings_Slow:
.byte "SLOW"

DrawValueString_Timer:
    lda Settables,y
    asl a
    tax
    lda TimerStrings,x
    sta $C0
    lda TimerStrings+1,x
    sta $C1
    lda #4
    sta $C2
    jmp DrawValueString

DrawValueString:
    clc
    lda VRAM_Buffer1_Offset
    tax
    adc $C2
    adc #3
    sta VRAM_Buffer1_Offset
    lda SettableRenderLocationsHi, y
    sta VRAM_Buffer1+0, x
    lda SettableRenderLocationsLo, y
    sta VRAM_Buffer1+1, x
    lda $C2
    sta VRAM_Buffer1+2, x
    ldy #0
@CopyNext:
    lda ($C0),y
    sta VRAM_Buffer1+3, x
    inx
    iny
    cpy $C2
    bcc @CopyNext
    lda #0
    sta VRAM_Buffer1+4, x
    rts



DrawValueNormal:
    clc
    lda VRAM_Buffer1_Offset
    tax
    adc #4
    sta VRAM_Buffer1_Offset
    lda SettableRenderLocationsHi, y
    sta VRAM_Buffer1+0, x
    lda SettableRenderLocationsLo, y
    sta VRAM_Buffer1+1, x
    lda #1
    sta VRAM_Buffer1+2, x
    lda Settables, y
    adc #1
    sta VRAM_Buffer1+3, x
    lda #0
    sta VRAM_Buffer1+4, x
    rts

UpdateValueFramerule:
    clc
    ldx MenuSelectedSubitem
    lda PressedButtons
    and #%00000011
    beq @update_value

    lda PressedButtons
    cmp #%00000001 ; right
    bne @check_left
    dex
@check_left:
    cmp #%00000010 ; left
    bne @store_selected
    inx
@store_selected:
    txa
    bpl @not_under
    lda #3
@not_under:
    cmp #4
    bcc @not_over
    lda #0
@not_over:
    sta MenuSelectedSubitem
    rts
@update_value:
    lda MathFrameruleDigitStart, x
    tay
    lda PressedButtons
    cmp #%00001000
    beq @increase
    dey
    bpl @store_value
    ldy #8
@increase:
    iny
    cpy #$A
    bne @store_value
    ldy #0
@store_value:
    tya
    sta MathFrameruleDigitStart, x
    rts

DrawValueFramerule:
    clc
    lda VRAM_Buffer1_Offset
    tax
    adc #7
    sta VRAM_Buffer1_Offset
    lda SettableRenderLocationsHi, y
    sta VRAM_Buffer1+0, x
    lda SettableRenderLocationsLo, y
    sta VRAM_Buffer1+1, x
    lda #4
    sta VRAM_Buffer1+2, x
    lda MathFrameruleDigitStart+0
    sta VRAM_Buffer1+3+3, x
    lda MathFrameruleDigitStart+1
    sta VRAM_Buffer1+3+2, x
    lda MathFrameruleDigitStart+2
    sta VRAM_Buffer1+3+1, x
    lda MathFrameruleDigitStart+3
    sta VRAM_Buffer1+3+0, x
    lda #0
    sta VRAM_Buffer1+3+4, x
    rts

BaseLocation = $20D3

.define SettableRenderLocations \
    BaseLocation + ($40 * 0), \
    BaseLocation + ($40 * 1), \
    BaseLocation + ($40 * 2) - 3, \
    BaseLocation + ($40 * 3) - 3, \
    BaseLocation + ($40 * 4) - 3

SettableRenderLocationsLo: .lobytes SettableRenderLocations
SettableRenderLocationsHi: .hibytes SettableRenderLocations
