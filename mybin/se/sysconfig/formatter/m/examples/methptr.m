class Bob;

typedef int (Bob::*BobPtr)(int*, int);
typedef int Bob::*BobMemberPointer;

void boid(void (Bob::*bob_action)(float), void (Bob::*)(int))
{

}
