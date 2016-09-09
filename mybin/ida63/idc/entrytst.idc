//
//      This example shows how to get list of entry points.
//

#include <idc.idc>

static main() {
  auto i;
  auto ord,ea;

  Message("Number of entry points: %ld\n",GetEntryPointQty());
  for ( i=0; ; i++ ) {
    ord = GetEntryOrdinal(i);
    if ( ord == 0 ) break;
    ea = GetEntryPoint(ord);
    Message("Entry point %08lX at %08lX (%s)\n",ord,ea,Name(ea));
  }
}
