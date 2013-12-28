#ifndef __$upcasesafeitemname$_H_INCL__
#define __$upcasesafeitemname$_H_INCL__

/**
 * TODO: Add class description
 * 
 * @author   $username$
 */
class $safeitemname$ {
public:
   // Method to fetch singleton instance.
   static $safeitemname$* getInstance();

   // Destructor
   virtual ~$safeitemname$();

protected:
   // Constructor - protected so users cannot call it.
   $safeitemname$();

private: 
   // private static member referencing the single instance of the object
   // TODO: Replace $safeitemname$ with the type of object you want to
   // return the single instance of
   static $safeitemname$* _instance;

   // Copy constructor
   // Declared but not defined to prevent auto-generated
   // copy constructor.  Refer to "Effective C++" by Meyers
   $safeitemname$(const $safeitemname$& src);

   // Assignment operator
   // Declared but not defined to prevent auto-generated
   // assignment operator.  Refer to "Effective C++" by Meyers
   $safeitemname$& operator=(const $safeitemname$& src);

};

// Constructor implementation
inline $safeitemname$::$safeitemname$()
{
}

// Destructor implementation
inline $safeitemname$::~$safeitemname$()
{
}

// TODO: Uncomment the copy constructor when you need it.
//inline $safeitemname$::$safeitemname$(const $safeitemname$& src)
//{
//   // TODO: copy
//}

// TODO: Uncomment the assignment operator when you need it.
//inline $safeitemname$& $safeitemname$::operator=(const $safeitemname$& rhs)
//{
//   if (this == &rhs) {
//      return *this;
//   }
//
//   // TODO: assignment
//
//   return *this;
//}

#endif // __$upcasesafeitemname$_H_INCL__
