class A
{
   public float calc(float c, float cx, float b)
   {
      float determinant=cx*cx*b/c;
      float n=norm(cx,b);
      SomeAlgorithm a = new SomeAlgorithm(determinant, n, b);
      return a.crunch();
   }
}
