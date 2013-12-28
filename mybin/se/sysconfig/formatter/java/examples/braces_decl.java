class Ladder {
   enum FooState {
      ON, OFF(12) {
         public int[] getSomething() {
            r = new int[] {1, 2, 3};
         }
      }
   }
   void statements(boolean cond, int x) {
      reg(new ISink() {
         public boolean drain() {
            return false;
         }
      });
   }
}
@interface Documented {
   int getRev();
}
