namespace Outer.Namespace {
   class Container {
      string Name {
         get {
            return "Container";
         }
      }
      void statements(boolean cond, int x){
         reg(new ISink() {
            public boolean drain() {
               return false;
            }
         });
      }
   }
}
