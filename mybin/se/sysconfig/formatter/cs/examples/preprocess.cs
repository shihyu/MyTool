#if COND
#define ILLIDIUM_PU36
#else
#define URANIUM_PU36
#endif
#if PROVIDER
void boid()
{
   if (cond) {
      #if URANIUM_PU36
      ux();
      #else
      ix();
      #endif
   }
}
#endif
#endif
