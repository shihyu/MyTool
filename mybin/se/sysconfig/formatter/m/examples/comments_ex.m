@interface BRK {
      /* This is state.
       * Watch it change over time.
       */
      char* base;          // base address
      unsigned int offset; // current offset.
      char* last;          // end of range.
// Column 1 comment
}

// Initialization
+ init;
@end

