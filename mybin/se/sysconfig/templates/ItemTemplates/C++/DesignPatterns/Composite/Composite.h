#ifndef __$upcasesafeitemname$_H_INCL__
#define __$upcasesafeitemname$_H_INCL__

#include <list>

class $safeitemname$Base;

typedef std::list<$safeitemname$Base*> $safeitemname$Collection;
typedef std::list<$safeitemname$Base*>::const_iterator $safeitemname$Iter;

/**
 * Any object that is to be stored in the composite tree 
 * structure must implement this interface.
 * 
 * @author $username$
 */
class $safeitemname$Base {
	protected:
		$safeitemname$Base(){}
	
	public:
		virtual void MemberFunction() = 0;
		virtual int get_NumberProperty() = 0;
		virtual void set_NumberProperty(int value) = 0;
		virtual int get_ChildCount() = 0;
		virtual $safeitemname$Iter Children() = 0;
		virtual int AddChild($safeitemname$Base* child) = 0;
		virtual int RemoveChild($safeitemname$Base* child) = 0;
};

/**
 * This class provides a standard implementation of the Component
 * class (leaf) as part of the Composite design pattern.  Objects 
 * of this type may not contain children.
 */
class $safeitemname$Component : public $safeitemname$Base {
	public:
		$safeitemname$Component() : _numberPropertyValue(0){}
		$safeitemname$Component(int value) : _numberPropertyValue(value){}
	private:
		
		int _numberPropertyValue;
	public:
		// Base class overrides
		void MemberFunction();
		int get_NumberProperty();
		void set_NumberProperty(int value);
		int get_ChildCount();
		$safeitemname$Iter Children();
		int AddChild($safeitemname$Base* child);
		int RemoveChild($safeitemname$Base* child);
};

/**
 * This class provides a standard implementation of the 
 * Composite class (node) as part of the Composite 
 * design pattern.  A Composite node may have one or
 * many children, but a Component (leaf) may not.
 */
class $safeitemname$Composite : public $safeitemname$Base {
	public:
		$safeitemname$Composite(){}
	private:
		$safeitemname$Collection _children;
	public:
		// Base class overrides
		void MemberFunction();
		int get_NumberProperty();
		void set_NumberProperty(int value);
		int get_ChildCount();
		$safeitemname$Iter Children();
		int AddChild($safeitemname$Base* child);
		int RemoveChild($safeitemname$Base* child);
};


#endif // __$upcasesafeitemname$_H_INCL__

