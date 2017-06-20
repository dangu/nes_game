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
    
class NESSound:
    """A class for handling NES sounds
    The conversion formula (according to
    http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=22776):
    P = C/(F*16) - 1
    
    P = Period
    C = CPU speed (in Hz)
    F = Frequency of the note (also in Hz).  
    
    The inverse will be:
    C/(F*16)= P + 1
    F*16/C    = 1/(P + 1)
    F       = C/(16*(P + 1))
    """
    def __init__(self, cpuFrequency):
        """Init"""
        self.cpuFrequency = cpuFrequency
        
    def freq2period(self, f):
        """Convert a given frequency to period"""
        p = self.cpuFrequency/(f*16.0) - 1
        return p
    
    def period2freq(self, p):
        """Convert a given period to frequency"""
        f = self.cpuFrequency/(16*(p + 1))
        return f
    
    def halftoneFactor(self, halftone):
        """The equally tempered scale is defined as
        2^(n/12) where n is the halftone number:
        n    note
        0    C
        1    C#
        2    D
        3    D#
        4    E
        5    F
        6    F#
        7    G
        8    G#
        9    A
        10   A#
        11   B
        12   C2"""
        factor = 2**(halftone/12.0)
        return factor
        
def testSound():
    """Test the sound class"""
    cpuFreqNTSC = 1790000
    cpuFreqPAL  = 1662607
    for note in range(24):
        s = NESSound(cpuFrequency = cpuFreqPAL)
        f = 220*s.halftoneFactor(note)
        p = s.freq2period(f)
        pRound = round(p)
        fRound = s.period2freq(pRound)
        fError = fRound-f
        
        print "Freq: %g\tPeriod: %g\tPeriod rounded: %g\tFreq rounded: %g\tFreq error: %g" %(f, p, pRound, fRound, fError)

if __name__=="__main__":
  #  writeBinary("test.chr")
    #writeTestPalette("test.pal")
    testSound()