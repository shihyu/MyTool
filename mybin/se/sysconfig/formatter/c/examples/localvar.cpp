   float Calc(float c, float cx, float b)
   {
      float determinant=cx*cx*b/c;
      float n=norm(cx,b);
      SomeAlgorithm *a = new SomeAlgorithm(determinant, n, b);
      SomeStruct scratch;
      return a->crunch(&scratch);
   }
