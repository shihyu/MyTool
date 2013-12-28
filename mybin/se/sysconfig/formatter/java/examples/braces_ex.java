class Ladder {
   void statements(boolean cond, int x) {
      try {
         if (cond) {
            bar();
         } else {
            bar();
         }
         for (int i = 0; i < 10; i++) {
            bar();
         }
         while (cond) {
            bar();
         }
         while (big
                && cond) {
            continue;
         }
         do {
            bar();
         }
         while (cond);

         switch (x) {
         case 0:
            break;
         }
      }
      catch (Excn& e) {
         bar();
      }
   }
}
