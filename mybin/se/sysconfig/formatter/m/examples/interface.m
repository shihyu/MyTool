@interface Pluggable (Discoverable) {
  char* devid;
  PluggableProxy pprox;
  int ref;
}

- (id)initWithSource: (id)src
                name: (id)uniqueName;

@end

@interface Explosive : Flammable <NSCopying, Printing>
@property(getter=getAProperty,atomic, readwrite, assign)id aProperty;
- kaBoom;
@end

@protocol SomeProtocol <ThisProtocol, ThatProtocol>
@required
- something;
@end

@implementation AnotherThing (ACategory)
@synthesize aProp, bProp, cProp=anInstanceVar;
@dynamic dProp, eProp;
-something;
@end
