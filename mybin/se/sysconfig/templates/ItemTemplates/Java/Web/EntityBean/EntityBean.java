package $packagename$;

import java.rmi.*;
import javax.ejb.*;

/**
 * TODO: Add class description
 * 
 * @author   $username$
 */
public class $safeitemname$ implements EntityBean {

    /**
     * Class member reference to the entity context
     */
    protected EntityContext _entityContext;

    /**
     * Default constructor
     */
    public $safeitemname$() {
	// TODO: add constructor code here
    }

    /**
     * A container invokes this method when the instance is taken
     * out of the pool of available instances to become associated
     * with a specific EJB object.
     */
    public void ejbActivate() throws EJBException, RemoteException {
	// TODO: add code to acquire any resource that was released earlier 
	// in the ejbPassivate() method
    }

    /**
     * A container invokes this method on an instance before the
     * instance becomes disassociated with a specific EJB object.
     */
    public void ejbPassivate() throws EJBException, RemoteException {
        // TODO: add code to release any resources that can be re-acquired
	// later in the ejbActivate() method
    }

    /**
     * A container invokes this method to instruct the instance to
     * synchronize its state by loading it state from the underlying
     * database.
     */
    public void ejbLoad() throws EJBException, RemoteException {
	// TODO: add code to load state
    }

    /**
     * A container invokes this method to instruct the instance to
     * synchronize its state by storing it to the underlying
     * database.
     */
    public void ejbStore() throws EJBException, RemoteException {
	// TODO: add code to persist state
    }

    /**
     * A container invokes this method before it removes the EJB
     * object that is currently associated with the instance.
     */
    public void ejbRemove() throws EJBException, RemoveException, RemoteException {
	// TODO: add code to release all resources
    }

    /**
     * Store the reference to the entity context object in an member
     * variable.
     * 
     * @param ctx An EntityContext interface for the instance.
     */
    public void setEntityContext(EntityContext ctx) throws EJBException, RemoteException {
	// store the session context
        _entityContext = ctx;
    }

    /**
     * Unset the reference to the entity context object in a member
     * variable.
     */
    public void unsetEntityContext() throws EJBException, RemoteException {
	// reset the session context
	_entityContext = null;
    }

}


