//
//      This example shows how to get list of marked positions.
//

#include <idc.idc>

static main() {
  auto x;

  MarkPosition(ScreenEA(),10,5,5,6,"Test of Mark Functions");
  for ( x=0; x<10; x++ )
    Message("%d: %a %s\n",x,GetMarkedPos(x),GetMarkComment(x));
}
