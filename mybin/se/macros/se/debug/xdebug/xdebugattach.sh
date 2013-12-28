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
#ifndef XDEBUG_ATTACH_SH
#define XDEBUG_ATTACH_SH

#define XDEBUG_ATTACH_NOTE '' \
          '<p style="font-family:Default Dialog Font; font-size:10">'        \
          'When debugging PHP you will typically want to set up a PHP '      \
          'project in order to take advantage of managed breakpoints, file ' \
          'organization, and Context Tagging. '                              \
          '</p>' \
          '<p style="font-family:Default Dialog Font; font-size:10">'           \
          'This dialog allows you to initiate an Xdebug debugging session '     \
          'in the absence of an active PHP project. This can be useful when:'   \
          '<ul>'                                                                \
          '<li>Your current project is not a PHP project, and </li>'            \
          '<li>You want to step-into the first statement of a script, or '      \
          '<li>You want to capture the stack from an unhandled exception, or '  \
          '<li>You have inserted manual breaks into your PHP code '             \
          '(e.g. ''xdebug_break'') which will break execution in the debugger.' \
          '</ul>'                                                               \
          '</p>' \
          '<p style="font-family:Default Dialog Font; font-size:10">'         \
          'Otherwise you are better served by creating a PHP project.'        \
          '</p>' \
          '<p style="font-family:Default Dialog Font; font-size:10">'         \
          'The PHP debugger uses the <a href="http://xdebug.org">Xdebug</a> ' \
          'extension for PHP. Set the local host and port to the host:port '  \
          'that Xdebug will attempt to connect to when initiating a debug '   \
          'sesson. <a href="slickc:help Running and Debugging PHP">See the help ' \
          'for more information about setting up debugging with Xdebug</a>.'  \
          '</p>'

#endif /* XDEBUG_ATTACH_SH */
