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

extern int _os390DSInfo2(_str dsname, var info);
extern int _os390IsMigrated(_str name);
extern int _os390ExecRexx(_str,_str);
extern int _os390BeginOpenedPDS();
extern int _os390EndOpenedPDS();
extern int _os390NewDS(_str dsname, _str volser, _str unit,
                int spaceUnit, int primary, int secondary,
                int dirBlocks, int recfm, int reclen,
                int blksize, int dsorg);
extern int _os390IsPDSMemberRegistered(_str dsname);
extern int _os390UnregisterPDSMembers(_str dsname);
extern int _os390RegisterPDSMembers(_str dsname);
extern int _os390DataSetStatInfo(_str dsname,var isFixed,var isPDS,var lrecl,var blkSize);
extern int _os390ListDataSet(_str dsname);
extern int _os390UnlistDataSet(_str dsname);
extern int _os390SubmitJCL(_str filename);
extern int _os390ENQ(_str dsname);
extern int _os390DEQ(_str dsname);
extern int _os390UnregisterPDSMemberList(_str dsname, var memberList);
extern int _os390DeleteDS(_str dsname);
extern int _os390UncatalogDS(_str dsname);
extern int _os390UncatalogDS(_str dsname);
extern int _os390FreeDS(_str dsname);
extern int _os390RenameDS(_str dsnameFrom, _str dsnameTo);
extern int _os390CatalogDS(_str dsname, _str volser);
