class Something<A> extends OrAnother
{

   public Something()
   {
       super(CTX_ST);
   }

   protected Stor getStorage() {
      if (isPickled() || needsReset() ||
          fullyQualifiedName() ==
          DEFAULT_NAME) {
         String file = storageFile();
         Pickle.load(file,
                      FLG_IMMEDIATE,
                      false);
      }
      return payload;
   }

    private A userdata;
    private static class StorageRep {
        int ref;
        char type;
        short refcnt;
    }
   }
}
