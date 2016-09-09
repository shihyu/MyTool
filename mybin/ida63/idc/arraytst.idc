//
//      This example shows how to use array manipulation functions.
//

#include <idc.idc>

#define MAXIDX  100

static main() {
  auto id,idx,code;

  id = CreateArray("my array");
  if ( id == -1 ) {
    Warning("Can't create array!");
  } else {

    Message("Filling array of longs...\n");
    for ( idx=0; idx < MAXIDX; idx=idx+10 )
      SetArrayLong(id,idx,2*idx);

    Message("Displaying array of longs...\n");
    for ( idx=GetFirstIndex(AR_LONG,id);
          idx != -1;
          idx=GetNextIndex(AR_LONG,id,idx) )
      Message("%d: %d\n",idx,GetArrayElement(AR_LONG,id,idx));

    Message("Filling array of strings...\n");
    for ( idx=0; idx < MAXIDX; idx=idx+10 )
      SetArrayString(id,idx,form("This is %d-th element of array",idx));

    Message("Displaying array of strings...\n");
    for ( idx=0; idx < MAXIDX; idx=idx+10 )
      Message("%d: %s\n",idx,GetArrayElement(AR_STR,id,idx));

  }

}
