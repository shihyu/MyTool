#ifndef __$upcasesafeitemname$_H_INCL__
#define __$upcasesafeitemname$_H_INCL__

#include <list>
#include <vector>

using namespace std;

class $safeitemname$;

/**
 * I$safeitemname$Observer defines the interface
 * that all observerss must implement to receive
 * notifications of updates to the subject.
 * 
 * @author   $username$
 */
class I$safeitemname$Observer {
public:
	// generic update function
	virtual void Update($safeitemname$* subject) = 0;
	// TODO: define any other notification functions
	// for observing subjects.  This is an interface, 
	// so all functions must be pure virtual ones.
};

/**
 * $safeitemname$ defines the class that all
 * observers will be observing.  It maintains 
 * an internal vector of listening subjects. 
 * The subject does not know what type of objects 
 * are observing it, only that they all implement 
 * the I$safeitemname$Observer interface.
 */
class $safeitemname$ {
public:
	// Constructor
	$safeitemname$();

	// Destructor
	virtual ~$safeitemname$();

	void Attach(I$safeitemname$Observer*);
	void Detach(I$safeitemname$Observer*);
	void Notify();

private:
	vector<I$safeitemname$Observer*> _observers;
};

#endif // __$upcasesafeitemname$_H_INCL__
