public class Statement {
   private void traverse(Node root, Vector<Integer> numbers) {
      int ct;
      Node n;

      for (ct = 0, n = root; n != null; ct++, n = n.next()) {
         do_something(n);
      }

      for (Integer num: numbers) {
         do_something(num);
      }
   }
}
