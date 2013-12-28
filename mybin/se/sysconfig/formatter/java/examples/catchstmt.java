class Statement {
   private boolean safe_foo(float dv)throws UncaughtException {
      try {
         foo(dv);
         return true;
      }
      catch (IOException|FileNodeFoundException e) {
         return false;
      }
      try (SomeHandle h = acquireThingy(dv)) {
         doSomething(h)
      }
   }
}
