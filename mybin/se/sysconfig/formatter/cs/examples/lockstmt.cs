class A : ISomething {
   private object _lock;

   void boid() {
      lock(_lock) {
         do_something();
      }
      log("A/boid: did something");
   }
}
