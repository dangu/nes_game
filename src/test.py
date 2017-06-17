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
    for x in range(32):
        f1.write(chr(x))
    f1.close() 

if __name__=="__main__":
    writeBinary("test.chr")
    writeTestPalette("test.pal")