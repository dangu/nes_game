def writeBinary(filename):
    """Writes binary data to file"""
    f1=open(filename, 'w')
    for x in range(8192):
        f1.write(chr((x*3)&0xFF))
    f1.close()

if __name__=="__main__":
    writeBinary("test.chr")
