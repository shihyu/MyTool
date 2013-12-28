public class Something : OrAnother
{
   public Something() : base(CTX_ST)
   {
   }

   public List<int> getStorage() {
      if (isPickled() || needsReset() ||
          fullyQualifiedName() ==
          DEFAULT_NAME) {
         string file = storageFile();
         Pickle.load(file,
                      FLG_IMMEDIATE,
                      false);
      }
      return m_payload;
   }

   private struct StorageRep<A> {
      int ref;
      char type;
      short refcnt;
      A proxy;
   };
};
