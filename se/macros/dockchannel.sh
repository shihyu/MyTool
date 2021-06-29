////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit name, logos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnify, hold harmless and defend SlickEdit from and 
//       against any loss, damage, claims or lawsuits, including attorney's fees, 
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////
#pragma option(metadata,"dockchannel.e")

struct DockChannelTab {
   int wid;
   _str uid;
   _str caption;
};
struct DockChannelInfo {
   int mdi_wid;
   DockAreaPos area;
   DockChannelTab tabs[];
};

extern void dc_get_info(int mdi_wid, int area, DockChannelInfo& info);
extern void dc_clear(int mdi_wid, DockAreaPos area);

