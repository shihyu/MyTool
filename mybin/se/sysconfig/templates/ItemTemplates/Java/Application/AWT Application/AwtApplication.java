import java.util.*;
import java.awt.*;
import java.awt.event.*;

/**
 * TODO: Add class description
 * 
 * @author   $username$
 */
public class $safeitemname$ extends Frame {

    /**
     * Class for handling all window events
     */
    public class $safeitemname$WindowHandler implements WindowListener {

	/**
	 * Quit the application when this window is closed
	 */
	public void windowClosing(WindowEvent we) {
	    // exit the program
	    System.exit(0);
	}
	// TODO: add custom window event handling code here
	public void windowClosed(WindowEvent we) {}
	public void windowIconified(WindowEvent we) {}
	public void windowOpened(WindowEvent we) {}
	public void windowDeiconified(WindowEvent we) {}
	public void windowActivated(WindowEvent we) {}
	public void windowDeactivated(WindowEvent we) {}
    }

    /**
     * Default constructor
     */
    public $safeitemname$() {
	// create the window event handler
	$safeitemname$WindowHandler windowHandler = new $safeitemname$WindowHandler();
	addWindowListener(windowHandler);
	// TODO: Add constructor code here
    }

    /**
     * Main entry point for the application
     * 
     * @param args List of command line arguments passed to the app
     */
    public static void main(String args[]) {
	// create the main application window
	Frame appWindow = new $safeitemname$();
	// set the window properties
	appWindow.setTitle("$itemname$");
	appWindow.setSize(600,400);
	appWindow.setBackground( new Color(215, 215, 215));
	appWindow.validate();
	// show the window
	appWindow.show(); 
    }

} 

