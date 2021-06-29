import java.awt.*;
import java.awt.event.*;

/**
 * 
 * 
 * @author 
 * @version 
 */
public class AboutDialog extends Dialog

{
   Button buttonOK = new Button();
   Label label2 = new Label();
   /**
    * constructor
    */
   public AboutDialog(Frame parent)
      throws HeadlessException {
      super(parent,true);
      try {
         initComponents();
      } catch (Exception e) {
         e.printStackTrace();
      }
   }

   private void initComponents() {
      this.setBounds(0, 0, 299, 164);
      this.setSize(299, 164);
      label2.setBounds(2, 46, 293, 41);
      label2.setText("A Basic AWT Application");
      label2.setSize(293, 41);
      label2.setFont(new Font("Dialog", Font.PLAIN, 12));
      buttonOK.setFont(new Font("Dialog", Font.PLAIN, 12));
      buttonOK.setLabel("OK");
      buttonOK.setSize(73, 32);
      buttonOK.setBounds(114, 111, 73, 32);
      label2.setAlignment(Label.CENTER);
      this.add(label2);
      this.add(buttonOK);
      buttonOK.addActionListener(new AboutDialog_buttonOK_ActionAdapter(this));
      this.setLayout(null);
      this.setTitle("Exit");
      this.addWindowListener(new AboutDialog_WindowAdapter(this));
   }

   /**
    * Shows or hides this component depending on the value of parameter
    * <code>b</code>.
    * @param b  If <code>true</code>, shows this component;
    * otherwise, hides this component.
    * <p>
    * Also centers the dialog in the middle of the parent frame.
    * </p>
    * @see java.awt.Component#isVisible
    */
   public void setVisible(boolean b) {
       if (b) {
           Rectangle bounds  = getParent().getBounds();
           Rectangle abounds = getBounds();

           setLocation(bounds.x + (bounds.width - abounds.width)/ 2,
                       bounds.y + (bounds.height - abounds.height)/2);
           Toolkit.getDefaultToolkit().beep();
       }
       super.setVisible(b);
   }

   /**
    * Events:  action
    * Method:  actionPerformed
    */
   void buttonOK_actionPerformed(java.awt.event.ActionEvent e0) {
      // add code here
      try {
          this.dispose();
      } catch (Exception e) {
      }
      
   }

   /**
    * Events:  window
    * Method:  windowClosing
    */
   void AboutDialog_windowClosing(java.awt.event.WindowEvent e0) {
      // add code here
      this.dispose();
   }

}

class AboutDialog_buttonOK_ActionAdapter implements ActionListener {
   AboutDialog adaptee;
   AboutDialog_buttonOK_ActionAdapter(AboutDialog adaptee) {
      this.adaptee=adaptee;
   }
   public void actionPerformed(java.awt.event.ActionEvent e0) {
      adaptee.buttonOK_actionPerformed(e0);
   }
}

class AboutDialog_WindowAdapter extends WindowAdapter {
   AboutDialog adaptee;
   AboutDialog_WindowAdapter(AboutDialog adaptee) {
      this.adaptee=adaptee;
   }
   public void windowClosing(java.awt.event.WindowEvent e0) {
      adaptee.AboutDialog_windowClosing(e0);
   }
}

