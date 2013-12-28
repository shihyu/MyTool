@interface Streamable
- (int)writeToStream: (id<Stream>)aStream 
       eightBitClean: (bool)isClean;

- reset;
@end
