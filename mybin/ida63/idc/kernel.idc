//
//      This file show how to insert you own comments for the imported DLLs.
//      This file inserts a comment for the kernel function #23 'LOCKSEGMENT'.
//      You may add your own comments for other functions and DLLs.
//      To execute this file your should choose 'Execute IDC file' command
//      from the IDA menu. Usually the  hotkey is F2.
//

static main(void) {
  auto faddr;
  auto fname;

  Message("Loading comments...\n");
  fname = form("KERNEL_%ld",23);        // build the function name
  faddr = LocByName(fname);             // get function address
  if ( faddr != -1 ) {                  // if the function exists
    ExtLinA(faddr,0,";컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴");
    ExtLinA(faddr,1,"; LockSegment (2.x)");
    ExtLinA(faddr,2,"; ");
    ExtLinA(faddr,3,"; In: AX - segment to lock");
    ExtLinA(faddr,4,";     LockSegment function locks the specified discardable");
    ExtLinA(faddr,5,"; segment. The segment is locked into memory at the given");
    ExtLinA(faddr,6,"; address and its lock count is incremented (increased by one).");
    ExtLinA(faddr,7,"; Returns");
    ExtLinA(faddr,8,"; The return value specifies the data segment if the function is");
    ExtLinA(faddr,9,"; successful. It is NULL if the segment has been discarded or an");
    ExtLinA(faddr,10,"; error occurs.");
  }
  Message("Comment(s) are loaded.\n");
}
