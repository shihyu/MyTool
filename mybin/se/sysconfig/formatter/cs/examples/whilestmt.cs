public class Stertment {
   protected void consume(Node n, int x)
   {
       while (n != null && n.isdead()) {
           eat(n);
           n = n.next();
       }

       do {
           n = n.next();
       } while (n != null && !n.isdead());
       blat();
   }
}
