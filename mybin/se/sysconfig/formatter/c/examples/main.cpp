class Something : public OrAnother
{
public:
   Something() : OrAnother(CTX_ST)
   {
   }

   int* getStorage() {
      if (isPickled() || needsReset() ||
          fullyQualifiedName() ==
          DEFAULT_NAME) {
         char const* file = storageFile();
         Pickle::load(file,
                      FLG_IMMEDIATE,
                      false);
      }
      return m_payload;
   }

private:
   template<class A>
   struct StorageRep {
      int* ref;
      char type;
      short refcnt;
      A* proxy;
   };
};
