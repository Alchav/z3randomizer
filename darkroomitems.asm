CheckReceivedItemPropertiesBeforeLoad:
    PHX
    LDA $7F504C : BEQ +
        LDA $7F504D : TAX
    +
    TXA
    PHY
    JSL.l MaybeLoadCrystalSpritePalette
    PLY
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

CrystalItemBehaviorCheck:
    LDA $0C5E, X : CMP.b #$20 : BNE .ordinaryItem
    LDA $0C54, X : CMP.b #$03 : BEQ .bossPrizeCrystal

.ordinaryItem
    JML.l CrystalFanfareContinue

.bossPrizeCrystal
    JML.l CrystalSpecialBehaviorContinue

MaybeLoadCrystalSpritePalette:
    PHA
    CMP.b #$20 : BEQ .loadPalette
    CMP.b #$B9 : BCC .done
    CMP.b #$C0 : BCS .done

.loadPalette
    PHX : PHY
    REP #$20
    LDA $00 : PHA
    LDA $02 : PHA
    SEP #$20

    LDA.b #$04 : STA $0AB1
    LDA.b #$02 : STA $0AA9
    JSL.l $1BED72 ; Palette_MiscSpr.justSP6
    INC $15

    REP #$20
    PLA : STA $02
    PLA : STA $00
    SEP #$20
    PLY
    PLX

.done
    PLA
RTL
