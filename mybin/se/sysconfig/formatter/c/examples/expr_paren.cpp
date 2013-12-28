float MagnitudeSquared(Vector3 const& v) {
   return (v.X * v.X) + (v.Y * v.Y) + (v.Z * v.Z);
}

bool sometest(Vector3 const& a, float sc) {
   if ((sc * a.X) - 1 > LIMIT) {
      return (a.Y > 0) || (a.Z < 0);
   }
   return (sc > 0.1) || (sc < 0.1);
}
