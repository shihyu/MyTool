#ifndef _SOME_HEADER_
#define _SOME_HEADER_

#if defined(COND)
#define ILLIDIUM_PU36
#else
#define URANIUM_PU36
#endif
#ifdef PROVIDER
void boid()
{
   if (cond) {
      #ifdef URANIUM_PU36
      ux();
      #else
      ix();
      #endif
   }
}
#endif
#endif
