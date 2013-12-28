public float MagnitudeSquared(Vector3 v) {
   return (v.X * v.X) + (v.Y * v.Y) + (v.Z * v.Z);
}

public boolean sometest(Vector3 a, float sc) {
   if ((sc * a.X) - 1 > LIMIT) {
      return (a.Y > 0) || (a.Z < 0);
   }
   return (sc > 0.1) || (sc < 0.1);
}
