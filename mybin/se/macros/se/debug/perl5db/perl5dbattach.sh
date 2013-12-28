////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#ifndef PERL5DB_ATTACH_SH
#define PERL5DB_ATTACH_SH

#define PERL5DB_ATTACH_NOTE '' \
          '<p style="font-family:Default Dialog Font; font-size:10">'        \
          'When debugging Perl you will typically want to set up a Perl '\
          'project in order to take advantage of managed breakpoints, file ' \
          'organization, and Context Tagging. '                              \
          '</p>' \
          '<p style="font-family:Default Dialog Font; font-size:10">'            \
          'This dialog allows you to initiate a Perl debugging session '       \
          'in the absence of an active Perl project. This can be useful when:' \
          '<ul>'                                                                 \
          '<li>Your current project is not a Perl project, and </li>'          \
          '<li>You want to step-into the first statement of a script, or '       \
          '<li>You want to capture the stack from an unhandled exception, or '   \
          '<li>You have inserted hard breaks into your Perl code '             \
          'which will break execution in the debugger.'                          \
          '</ul>'                                                                \
          '</p>' \
          '<p style="font-family:Default Dialog Font; font-size:10">'     \
          'Otherwise you are better served by creating a Perl project.' \
          '</p>' \
          '<p style="font-family:Default Dialog Font; font-size:10">'      \
          'The Perl debugger uses the DBGp client script (perl5db.pl). '  \
          'Set the local host and port to the host:port that perl5db will ' \
          'attempt to connect to when initiating a debug sesson. '         \
          '<a href="slickc:help Running and Debugging Perl">See the help for '  \
          'more information about setting up debugging with perl5db</a>.'   \
          '</p>'

#endif /* PERL5DB_ATTACH_SH */
