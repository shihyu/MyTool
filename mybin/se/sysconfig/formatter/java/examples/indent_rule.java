   class B {
      enum State {
         ON,
         OFF(123) {
            public int getSomething() {
               return blarp;
            }
         }
      }
   public void cpu_space_heater(State x)
      {
         start:
         switch (x) {
         case ON:
            goto start;
         default:
            {
               goto start;
            }
         }
      }
   }
   @interface Mouse {
      int getCheese() default 0;
   }
