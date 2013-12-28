@interface Pluggable (Discoverable) {
  @public
  char* devid;
  PluggableProxy pprox;
  @private
  int ref;
  // may be null
  Controller* myController;
}

- (id)initWithSource: (id)src
                name: (id)uniqueName;
- (ResponseType)ping: (Req)ty;

@end

@implementation Pluggable
- (id)initWithSource: (id)src
                name: (id)uniqueName
{
    [self cleanInitSource:src name:uniqueName]
}
- (ResponseType)ping: (Req)ty
{
    return [self handleRequest: ty];
}

@end
