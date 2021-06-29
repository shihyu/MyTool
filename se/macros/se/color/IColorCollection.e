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
#pragma option(pedantic,on)

/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information 
 * within SlickEdit. 
 */
namespace se.color;

/**
 * This interface is used to represent something which contains a 
 * collection of colors.  The colors may be looked up either by name 
 * or by color id, as allocated by {@link _AllocColor()}. 
 */
interface IColorCollection {

   /** 
    * @return  
    * Return a pointer to the color information object associated with 
    * the given color name.  Color names do not have to be universally 
    * unique, only unique within this collection. 
    * <p> 
    * Return null if there is no such color or if this collection does 
    * not index colors by name. 
    *  
    * @param name    color name 
    */
   class ColorInfo *getColorByName(_str name);

};

