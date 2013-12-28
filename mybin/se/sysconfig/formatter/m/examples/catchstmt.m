@implementation Something
- (bool)foo: (float)dv {
   @try {
      [something bad];
      return true;
   } @catch(NSException* e) {
      return false;
   } @finally {
	   cleanup();
   }
   bork();
}
@end
