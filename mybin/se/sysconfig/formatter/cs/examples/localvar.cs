class A
{
   float Calc(float c, float cx, float b)
   {
      var determinant=cx*cx*b/c;
      var n=norm(cx,b);
      SomeAlgorithm a = new SomeAlgorithm(determinant, n, b);
      SomeStruct scratch;
      return a.crunch(ref scratch);
   }
}
