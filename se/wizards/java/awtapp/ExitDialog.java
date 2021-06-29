import java.awt.*;
import java.awt.event.*;

/**
 * 
 * 
 * @author 
 * @version 
 */
public class ExitDialog extends Dialog

{
   Button buttonYes = new Button();
   Button buttonNo = new Button();
   Label label2 = new Label();
   Frame frameParent;
   /**
    * constructor
    */
   public ExitDialog(Frame parent)
      throws HeadlessException {
      super(parent,true);
      frameParent=parent;
      try {
         initComponents();
      } catch (Exception e) {
         e.printStackTrace();
      }
   }

   private void initComponents() {
      this.setBounds(0, 0, 286, 163);
      this.setSize(286, 163);
      label2.setBounds(2, 46, 280, 41);
      label2.setText("Exit?");
      label2.setSize(280, 41);
      label2.setFont(new Font("Dialog", Font.PLAIN, 12));
      buttonNo.setFont(new Font("Dialog", Font.PLAIN, 12));
      buttonNo.setLabel("No");
      buttonNo.setSize(73, 32);
      buttonNo.setBounds(189, 106, 73, 32);
      buttonYes.setFont(new Font("Dialog", Font.PLAIN, 12));
      buttonYes.setLabel("Yes");
      buttonYes.setSize(73, 32);
      buttonYes.setBounds(32, 108, 73, 32);
      label2.setAlignment(Label.CENTER);
      this.add(label2);
      this.add(buttonYes);
      this.add(buttonNo);
      buttonNo.addActionListener(new ExitDialog_buttonNo_ActionAdapter(this));
      buttonYes.addActionListener(new ExitDialog_buttonYes_ActionAdapter(this));
      this.setLayout(null);
      this.setTitle("Exit");
      this.addWindowListener(new ExitDialog_WindowAdapter(this));
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
   void buttonYes_actionPerformed(java.awt.event.ActionEvent e0) {
      try {
          // Hide the invoking parent_frame
          frameParent.setVisible(false);
          // Free system resources
          frameParent.dispose();
          this.dispose();
          // Close the application
          System.exit(0);
      } catch (Exception e) {
      }
      
   }

   /**
    * Events:  action
    * Method:  actionPerformed
    */
   void buttonNo_actionPerformed(java.awt.event.ActionEvent e0) {
      // add code here
      // add code here
      this.dispose();
   }

   /**
    * Events:  window
    * Method:  windowClosing
    */
   void ExitDialog_windowClosing(java.awt.event.WindowEvent e0) {
      // add code here
      this.dispose();
   }

}

class ExitDialog_buttonYes_ActionAdapter implements ActionListener {
   ExitDialog adaptee;
   ExitDialog_buttonYes_ActionAdapter(ExitDialog adaptee) {
      this.adaptee=adaptee;
   }
   public void actionPerformed(java.awt.event.ActionEvent e0) {
      adaptee.buttonYes_actionPerformed(e0);
   }
}

class ExitDialog_buttonNo_ActionAdapter implements ActionListener {
   ExitDialog adaptee;
   ExitDialog_buttonNo_ActionAdapter(ExitDialog adaptee) {
      this.adaptee=adaptee;
   }
   public void actionPerformed(java.awt.event.ActionEvent e0) {
      adaptee.buttonNo_actionPerformed(e0);
   }
}

class ExitDialog_WindowAdapter extends WindowAdapter {
   ExitDialog adaptee;
   ExitDialog_WindowAdapter(ExitDialog adaptee) {
      this.adaptee=adaptee;
   }
   public void windowClosing(java.awt.event.WindowEvent e0) {
      adaptee.ExitDialog_windowClosing(e0);
   }
}

