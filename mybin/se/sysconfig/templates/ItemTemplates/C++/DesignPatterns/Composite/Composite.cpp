#include "$fileinputname$.h"

/**
 * Example of a member function that may be performed on 
 * this object. 
 * TODO: Rename and implement this function
 */
void $safeitemname$Composite::MemberFunction() {
	$safeitemname$Iter it;
	// iterate over each child
	for(it = _children.begin(); it != _children.end(); ++it)
	{
		// call that child's member function
		$safeitemname$Base* child = *it;
		child->MemberFunction();
	}
}

/**
 * Example number property getter.  Simply gets the number
 * property from each child object and adds them.
 * 
 * @return   The sum of all numbers contained in the leaves
 *         under this node in the composite tree.
 */
int $safeitemname$Composite::get_NumberProperty() {
	int sum = 0;
	$safeitemname$Iter it;
	// traverse the children
	for(it = _children.begin(); it != _children.end(); ++it)
	{
		// sum their values
		$safeitemname$Base* child = *it;
		sum += child->get_NumberProperty();
	}
	return sum;
}

/**
 * Example of a numeric property setter
 */
void $safeitemname$Composite::set_NumberProperty(int value) {
	// No-op
}

/**
 * Returns the number of children contained by this composite node
 */
int $safeitemname$Composite::get_ChildCount() {
	return (int)_children.size();
}

/**
 * Returns an iterator for the child collection
 */
$safeitemname$Iter $safeitemname$Composite::Children() {
	return _children.begin();
}

/**
 * Adds a new child to the node
 * 
 * @param child A new child to be added to the child collection
 * 
 * @return The number of children owned by this object
 */
int $safeitemname$Composite::AddChild($safeitemname$Base* child) {
	_children.push_back(child);
	return (int)_children.size();
}

/**
 * Removes a specific child from the node
 * 
 * @param child The child object to be removed from the child
 *              collection
 * 
 * @return The number of children owned by this object
 */
int $safeitemname$Composite::RemoveChild($safeitemname$Base* child) {
	_children.remove(child);
	return (int)_children.size();
}


