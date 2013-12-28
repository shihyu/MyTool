class Statement {
   private boolean safe_foo(float dv) {
      try {
         foo(dv);
         return true;
      }
      catch (System.DivideByZeroException& e) {
         return false;
      }
      finally { 
         log_something();
      }
   }
}
