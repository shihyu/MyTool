#include "$fileinputname$.h"

/**
 * Example of a member function that may be performed on 
 * this object.
 */
void $safeitemname$Component::MemberFunction() {
	// TODO: Component method implementation
}

/**
 * Example of a numeric property getter
 */
int $safeitemname$Component::get_NumberProperty() {
	return _numberPropertyValue;
}

/**
 * Example of a numeric property setter
 */
void $safeitemname$Component::set_NumberProperty(int value) {
	_numberPropertyValue = value;
}

/**
 * A component has no children, so return 0
 */
int $safeitemname$Component::get_ChildCount() {
	return 0;
}

/**
 * A component has no children, so return null
 */
$safeitemname$Iter $safeitemname$Component::Children() {
	return 0;
}

/**
 * AddChild has no implementation in the component class
 */
int $safeitemname$Component::AddChild($safeitemname$Base* child) {
	return 0;
}

/**
 * RemoveChild has no implementation in the component class
 */
int $safeitemname$Component::RemoveChild($safeitemname$Base* child) {
	return 0;
}


