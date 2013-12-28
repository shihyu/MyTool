void boid(id* obj, 
          int a, 
          int b,
          int *x)
{
   if (![obj within: a 
           andAlso:b ]) {
      [obj expandRangeToCover: a];
      [obj expandRangeToCover: b];
      [obj apply: ^(int x) {
        if x > 0 {
          return 2 * x;
          } else {
            return 0;
          }];
      *x = [obj width] + b
      +12;
   }
}
