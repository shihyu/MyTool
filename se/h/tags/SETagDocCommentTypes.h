////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SETagDocCommentTypes.h
// Description:   Declaration of enumerated type listing types of documentation
//                comments we support.
////////////////////////////////////////////////////////////////////////////////
#pragma once


/** 
 * Documentation comment types
 */
enum SETagDocCommentType {
   /**
    * No documentation comment for this symbol.
    */
   SE_TAG_DOCUMENTATION_NULL,
   /**
    * Plain text, no comment characters, can have newlines.
    */
   SE_TAG_DOCUMENTATION_PLAIN_TEXT,
   /**
    * Plain text, expecting fixed-space font, no comment characters, can have newlines.
    */
   SE_TAG_DOCUMENTATION_FIXED_FONT_TEXT,
   /**
    * HTML formatted text, can have newlines.
    */
   SE_TAG_DOCUMENTATION_HTML,
   /**
    * Raw JavaDoc comment, including comment characters and newlines.
    */
   SE_TAG_DOCUMENTATION_RAW_JAVADOC,
   /**
    * Raw Doxygen comment, including comment characters and newlines.
    */
   SE_TAG_DOCUMENTATION_RAW_DOXYGEN,
   /**
    * Raw XMLDoc comment, including comment characters and newlines.
    */
   SE_TAG_DOCUMENTATION_RAW_XMLDOC,
   /**
    * JavaDoc comment with comment characters stripped, can have newlines.
    */
   SE_TAG_DOCUMENTATION_JAVADOC,
   /**
    * Doxygen comment with comment characters stripped, can have newlines.
    */
   SE_TAG_DOCUMENTATION_DOXYGEN,
   /**
    * XMLDoc comment with comment characters stripped, can have newlines.
    */
   SE_TAG_DOCUMENTATION_XMLDOC,
   /**
    * Invalid comment type
    */
   SE_TAG_DOCUMENTATION_INVALID
};


