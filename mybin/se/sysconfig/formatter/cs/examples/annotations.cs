@Deprecated package com.test;

@Deprecated public class Notes {
   @Override public String toString() {
      return "nerf";
   }
   @Documented private String name;

   @Documented @ConformsTo(1,2) void boid(@SuppressWarning("unused")int x) {
      @SuppressWarning("unused") int y;
      do_something();
   }
}
