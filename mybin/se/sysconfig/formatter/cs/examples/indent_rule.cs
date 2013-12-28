public class Util {
   public static void cpu_space_heater(State x)
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
}
