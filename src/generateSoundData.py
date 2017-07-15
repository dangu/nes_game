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
        self.f1 = None
        
    def open(self, filename):
        """Open file for writing"""
        self.f1 = open(filename, 'w')
    
    def close(self):
        """Close output file"""
        self.f1.close()
        
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
    def generateNoteTable(self):
        """Generate a note table that can be imported to
        NESASM-programs
        The definition is A4 = 440Hz
        
        C5 is 3 halftones above A4
        C4 is 9 halftones below A4
        C3 is 12 halftones below C4, 21 halftones below A4
        C1 is 21+24=45 halftones below A4
        """
        names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

        f1 = self.f1
        
        freqA4 = 440 # [Hz]
        # Loop from C1 to C5
        notes = []
        for octave in range(1, 9+1):
            baseHalftoneNumber = 12*(octave-1) - 45 # C1 is 45 halftones below A4
            notesInOctave = []
            for halftoneNumberInOctave in range(0, 12):
                halftoneNumber = baseHalftoneNumber + halftoneNumberInOctave
                note = {}            
                note['octave'] = octave
                note['name'] = names[halftoneNumberInOctave]
                note['freq'] = freqA4*self.halftoneFactor(halftoneNumber)
                note['period'] = self.freq2period(note['freq'])
                notesInOctave.append(note)
            notes.append(notesInOctave)
        

        # Write header
        f1.write("; Frequency values [Hz]\n; ")
        for notename in names:
            f1.write("%8s" %(notename))
        f1.write("\n")
        for octave in notes:
            f1.write(";    ")
            for note in octave:
                f1.write("%8s" %("%.1f " %(note['freq'])))
            f1.write("; Octave %d\n" %(note['octave']))
        f1.write("\n")
        
        f1.write("; Period values, floating point\n; ")
        for notename in names:
            f1.write("%8s" %(notename))
        f1.write("\n")
        for octave in notes:
            f1.write(";    ")
            for note in octave:
                f1.write("%8s" %("%.1f " %(note['period'])))
            f1.write("; Octave %d\n" %(note['octave']))
        f1.write("\n")

        f1.write("; Frequency error (actual - wanted)[Hz]\n; ")
        for notename in names:
            f1.write("%8s" %(notename))
        f1.write("\n")
        for octave in notes:
            f1.write(";    ")
            for note in octave:
                f1.write("%8s" %("%.1f " %(self.period2freq(round(note['period']))-note['freq'])))
            f1.write("; Octave %d\n" %(note['octave']))
        f1.write("\n")
                    
        f1.write("; Period values, rounded nearest\n; ")
        for notename in names:
            f1.write("%8s" %(notename))
        f1.write("\n")
        for octave in notes:
            f1.write(";    ")
            for note in octave:
                f1.write("%8s" %("%d " %(round(note['period']))))
            f1.write("; Octave %d\n" %(note['octave']))
        f1.write("\n")
        
        f1.write("; Period values, rounded nearest, hex\n;     ")
        for notename in names:
            f1.write("%8s" %(notename))
        f1.write("\n")
        for octave in notes:
            row = "    .word "
            for note in octave:
                row +="%8s" %("$%04X, " %(round(note['period'])))
            row = row[:-2]  # Remove trailing ','
            
            f1.write("%s ; Octave %d\n" %(row, note['octave']))
        f1.write("\n")
        
        # Define a dummy period for a rest
        f1.write("; Rest (dummy value)\n")
        f1.write("    .word $0000\n\n")
        
        # Write the corresponding note defines, for example "Cs1" for C# first octave
        f1.write("; Note defines\n")
        offset = 0
        for octave in notes:
            for note in octave:
                # C# => Cs
                assemplerNoteName = note['name'].replace('#','s')
                completeNoteName = "%s%d" %(assemplerNoteName, note['octave'])
                f1.write("%-3s = $%02X\n" %(completeNoteName, offset))
                
                # Ugly hack to produce Db out of C#
                if(note['name'].count('#')):
                    # G# => Ab and not Hb
                    if(note['name'][0]=='G'):
                        completeNoteName2 = "Ab%d" %(note['octave'])
                    else:
                        completeNoteName2 = "%sb%d" %(chr(ord(note['name'][0])+1), note['octave'])

                    f1.write("%-3s = $%02X\n" %(completeNoteName2, offset))
                                            
                
                offset += 1
        
        f1.write("\n; The rest will have the index $%02X in the table:\n" %offset)
        f1.write("rest = $%02X\n" %offset)
            
        f1.write("\nnote_length_table:\n")
        f1.write("    .byte $01    ; 32nd note\n")
        f1.write("    .byte $02    ; 16th note\n")
        f1.write("    .byte $04    ; 8th note\n")
        f1.write("    .byte $08    ; quarter note\n")
        f1.write("    .byte $10    ; half note\n")
        f1.write("    .byte $20    ; whole note\n\n")
        
        f1.write("; Note length defines (for using defining a song)\n")
        f1.write("thirtysecond = $80\n")
        f1.write("sixteenth    = $81\n")
        f1.write("eighth       = $82\n")
        f1.write("quarter      = $83\n")
        f1.write("half         = $84\n")
        f1.write("whole        = $85\n")
    
    def generateVolumeEnvelopes(self):
        """Create the volume envelopes"""
        self.f1.write("\n; Volume envelopes\n")
        
        # Define some envelopes
        envelopeDataList = [[15, 14, 13, 6, 3, 0],
                        [15, 5, 15, 5, 15, 5],]
        envelopeNumber = 1
        envelopeNameList = []
        
        # Loop through all envelopes
        for envelopeData in envelopeDataList:     
            envelopeName = "se_ve_%d" %envelopeNumber
            self.f1.write(envelopeName + ":\n")
            envelopeNameList.append(envelopeName)
            self.f1.write("    .byte ")
            
            envelopeDataString = ""
            for data in envelopeData:
                if not (0<=data<=0x0F):
                    raise ValueError("Encountered an invalid volume value (%d=0x%02X)" %(data, data))
                envelopeDataString += "$%02X, " %data
            envelopeDataString = envelopeDataString[:-2] # Strip off the last ","
            self.f1.write(envelopeDataString)
            self.f1.write("\n    .byte $FF\n")
           
            envelopeNumber += 1
            
        # Now create the table of volume envelopes
        self.f1.write("\n; Table of volume envelopes:\n")
        self.f1.write("volume_envelopes:\n")
        envelopeTableString = ""
        for envelopeName in envelopeNameList:
            envelopeTableString += "%s, " %envelopeName
        envelopeTableString = envelopeTableString[:-2] # Strip off the last ", "
        self.f1.write("   .word %s\n" %envelopeTableString)
        
def testSound():
    """Test the sound class"""
    cpuFreqNTSC = 1790000
    cpuFreqPAL  = 1662607
    s = NESSound(cpuFrequency = cpuFreqNTSC)
    s.generateNoteTable("sound_data.asm")
    
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
    #testSound()
    
    cpuFreqNTSC = 1790000
    cpuFreqPAL  = 1662607
    s = NESSound(cpuFrequency = cpuFreqNTSC)
    filename = "sound_data.asm"
    s.open(filename)
    s.generateNoteTable()
    s.generateVolumeEnvelopes()
    s.close()
    
    print "Finished generating data file " + filename