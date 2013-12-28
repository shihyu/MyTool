public class Statement {
   private void traverse(Node root, List<int> numbers) {
      int ct;
      Node n;

      for (ct = 0, n = root; n != null; ct++, n = n.next()) {
         do_something(n);
      }

      foreach (int num in numbers) {
         do_something(num);
      }
   }
}
