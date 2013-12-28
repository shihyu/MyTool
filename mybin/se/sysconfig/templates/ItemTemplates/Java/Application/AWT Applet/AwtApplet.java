import java.applet.*;
import java.awt.*;

/**
 * TODO: Add class description
 * 
 * @author   $username$
 */
public class $safeitemname$ extends Applet {
    /**
     * The method that will be automatically called  when the applet is started
     */
    public void init() {
	// TODO: Add start up functionality
    }

    /**
     * This method gets called when the applet is terminated
     */
    public void stop() {
	// TODO: Add shut down functionality
    }

    /**
     * Override the paint method to draw using the Graphics object
     * 
     * @param g A reference to the graphics object for painting
     */
    public void paint(Graphics g) {
	// draw a rectangle around the border
        g.drawRect(0, 0, getSize().width - 1, getSize().height - 1);
	// draw text
	g.drawString("$itemname$",20,20);
    }

} 


