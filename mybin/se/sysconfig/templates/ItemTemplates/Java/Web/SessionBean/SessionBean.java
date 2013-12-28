package $packagename$;

import java.rmi.*;
import javax.ejb.*;

/**
 * TODO: Add class description
 * 
 * @author   $username$
 */
public class $safeitemname$ implements SessionBean {

    /**
     * Class member reference to the session context
     */
    protected SessionContext _sessionContext;

    /**
     * Default constructor
     */
    public $safeitemname$() {
	// TODO: add constructor code here
    }

    /**
     * The activate method is called when the instance is activated
     * from its "passive" state.
     */
    public void ejbActivate() throws EJBException, RemoteException {
	// TODO: add code to acquire any resource that was released earlier 
	// in the ejbPassivate() method
    }

    /**
     * The passivate method is called before the instance enters the
     * "passive" state.
     */
    public void ejbPassivate() throws EJBException, RemoteException {
        // TODO: add code to release any resources that can be re-acquired
	// later in the ejbActivate() method
    }

    /**
     * A container invokes this method before it ends the life of
     * the session object.
     */
    public void ejbRemove() throws EJBException, RemoteException {
	// TODO: add code to release all resources
    }

    /**
     * Store the reference to the entity context object in an member
     * variable.
     * 
     * @param ctx A SessionContext interface for the instance.
     */
    public void setSessionContext(SessionContext ctx) throws EJBException, RemoteException {
	// store the session context
        _sessionContext = ctx;
    }

}




