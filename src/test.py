def writeBinary(filename):
    """Writes binary data to file"""
    f1=open(filename, 'w')
    for x in range(8192):
        f1.write(chr((x*3)&0xFF))
    f1.close()
    
def writeTestPalette(filename):
    """Write a test palette (20 bytes)
    
lda #$01
lda #$02 
lda #$03
lda #$04
lda #$05
lda #$06
lda #$07
lda #$08
lda #$01     ;stop here
lda #$08
lda #$09
lda #$0A
lda #$01
lda #$0B
lda #$0C
lda #$0D
lda #$01    ;Start sprite colors
lda #$0D
lda #$08
lda #$2B
lda #$01
lda #$05
lda #$06
lda #$07
lda #$01
lda #$08
lda #$09
lda #$0A
lda #$01        
lda #$0B
lda #$0C
lda #$0D
        
"""
    f1=open(filename, 'w')
    
    # Palette memory according to https://wiki.nesdev.com/w/index.php/PPU_palettes
    data = [0x0E, # 0x3F00    Universal background color
            0x0E, 0x20, 0x20, 0x20, # 0x3F01-0x3F03    Background pal 0
            0x20, 0x20, 0x00, 0x00, # 0x3F05-0x3F73    Background pal 1
            0x20, 0x00, 0x00, 0x00, # 0x3F09-0x3F0B    Background pal 2
            0x20, 0x00, 0x00, 0x00, # 0x3F0D-0x3F0F    Background pal 3
            0x30, 0x31, 0x34, 0x2A, # 0x3F11-0x3F13    Sprite palette 0
            0x20, 0x00, 0x00, 0x00, # 0x3F15-0x3F17    Sprite palette 1
            0x20, 0x00, 0x00, 0x00, # 0x3F19-0x3F1B    Sprite palette 2
            0x20, 0x00, 0x00, 0x00] # 0x3F1D-0x3F1F    Sprite palette 3


    for x in data:
        f1.write(chr(x))
    
    f1.close() 

if __name__=="__main__":
  #  writeBinary("test.chr")
    writeTestPalette("test.pal")