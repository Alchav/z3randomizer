; Load received-item palette properties, using the boss-prize display item when
; the receive animation is showing a substituted/progressive prize.
CheckReceivedItemPropertiesBeforeLoad:
    PHX
    LDA $7F504C : BEQ +
        LDA $7F504D : TAX
    +
    LDA $A0 : BEQ .normalCode
    LDA $7EC005 : BNE .lightOff
    .normalCode
    JSR .loadProperty
    PLX
    CMP.b #$00 ; preserve vanilla BPL behavior by setting flags from the loaded property, not restored X
    RTL

    .lightOff
    PHY : PHB
    JSR .loadProperty

    REP #$30
    AND #$0007 ; mask out palette
    ASL #5 ; multiply by 32
    ADC #$C610 ; offset to latter half

    TAX ; give to destination
    LDY #$C610 ; target palette SP0 colors 8-F

    LDA #$000F ; 16 bytes
    MVN $7E, $7E ; move palette

    SEP #$30
    PLB : PLY : PLX
    INC $15
    LDA #$00
    RTL

    ; Swords and shields use inventory-dependent palette properties, so boss
    ; prizes need the resolved display item rather than the original item ID.
    .loadProperty
    LDA $7F504C : BEQ .normalProperty
    TXA : CMP.b #$49 : BEQ .masterSword
          CMP.b #$01 : BEQ .masterSword
          CMP.b #$50 : BEQ .masterSword
          CMP.b #$02 : BEQ .temperedSword
          CMP.b #$03 : BEQ .goldenSword
          CMP.b #$04 : BCC .normalProperty
          CMP.b #$07 : BCC .shield

    .normalProperty
    LDA.l AddReceivedItemExpanded_properties, X ; Restore Rando Code
    RTS

    .masterSword
    LDA.b #$02
    RTS

    .temperedSword
    LDA.b #$01
    RTS

    .goldenSword
    LDA.b #$04
    RTS

    .shield
    LDA.b #$05
    RTS

; Boss-prize crystals are spawned as ordinary receive-item objects, but still
; need the crystal-specific fanfare/state path once they are collected.
CrystalItemBehaviorCheck:
    LDA $0C5E, X : CMP.b #$20 : BNE .ordinaryItem
    LDA $0C54, X : CMP.b #$03 : BEQ .bossPrizeCrystal

.ordinaryItem
    JML.l CrystalFanfareContinue

.bossPrizeCrystal
    JML.l CrystalSpecialBehaviorContinue
