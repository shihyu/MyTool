import java.awt.*;
import java.awt.event.*;

/**
 * 
 * 
 * @author 
 * @version 
 */
public class CLASSNAME extends Frame

{
   MenuItem menuItemAbout = new MenuItem();
   Menu menuHelp = new Menu();
   MenuItem menuItemPaste = new MenuItem();
   MenuItem menuItemCopy = new MenuItem();
   MenuItem menuItemCut = new MenuItem();
   Menu menuEdit = new Menu();
   MenuItem menuItemExit = new MenuItem();
   MenuItem menuItemSaveAs = new MenuItem();
   MenuItem menuItemSave = new MenuItem();
   MenuItem menuItemOpen = new MenuItem();
   MenuItem menuItemNew = new MenuItem();
   Menu menuFile = new Menu();
   MenuBar menuBar1 = new MenuBar();
   /**
    * constructor
    */
   public CLASSNAME(java.awt.GraphicsConfiguration a0) {
      super(a0);
      try {
         initComponents();
      } catch (Exception e) {
         e.printStackTrace();
      }
   }

   /**
    * constructor
    */
   public CLASSNAME(java.lang.String a0)
      throws HeadlessException {
      super(a0);
      try {
         initComponents();
      } catch (Exception e) {
         e.printStackTrace();
      }
   }

   /**
    * constructor
    */
   public CLASSNAME(java.lang.String a0, java.awt.GraphicsConfiguration a1) {
      super(a0, a1);
      try {
         initComponents();
      } catch (Exception e) {
         e.printStackTrace();
      }
   }

   /**
    * constructor
    */
   public CLASSNAME()
      throws HeadlessException {
      super();
      try {
         initComponents();
      } catch (Exception e) {
         e.printStackTrace();
      }
   }

   private void initComponents() {
      this.setBounds(0, 0, 784, 614);
      this.setSize(784, 614);
      this.setMenuBar(menuBar1);
      this.addWindowListener(new CLASSNAME_WindowAdapter(this));
      menuFile.setLabel("File");
      menuBar1.add(menuFile);
      menuEdit.setLabel("Edit");
      menuBar1.add(menuEdit);
      menuHelp.setLabel("Help");
      menuBar1.add(menuHelp);
      menuItemNew.setLabel("New");
      menuItemNew.setShortcut(new MenuShortcut(KeyEvent.VK_N, false));
      menuFile.add(menuItemNew);
      menuItemOpen.setLabel("Open...");
      menuItemOpen.setShortcut(new MenuShortcut(KeyEvent.VK_O, false));
      menuItemOpen.addActionListener(new CLASSNAME_menuItemOpen_ActionAdapter(this));
      menuFile.add(menuItemOpen);
      menuItemSave.setLabel("Save");
      menuItemSave.setShortcut(new MenuShortcut(KeyEvent.VK_S, false));
      menuFile.add(menuItemSave);
      menuItemSaveAs.setLabel("Save As...");
      menuFile.add(menuItemSaveAs);
      menuFile.addSeparator();
      menuItemExit.setLabel("Exit");
      menuItemExit.addActionListener(new CLASSNAME_menuItemExit_ActionAdapter(this));
      menuFile.add(menuItemExit);
      menuItemCut.setLabel("Cut");
      menuItemCut.setShortcut(new MenuShortcut(KeyEvent.VK_X, false));
      menuEdit.add(menuItemCut);
      menuItemCopy.setLabel("Copy");
      menuItemCopy.setShortcut(new MenuShortcut(KeyEvent.VK_C, false));
      menuEdit.add(menuItemCopy);
      menuItemPaste.setLabel("Paste");
      menuItemPaste.setShortcut(new MenuShortcut(KeyEvent.VK_V, false));
      menuEdit.add(menuItemPaste);
      menuItemAbout.setLabel("About...");
      menuItemAbout.addActionListener(new CLASSNAME_menuItemAbout_ActionAdapter(this));
      menuHelp.add(menuItemAbout);
   }


   /**
    * Main method
    */
   public static void main(String args[]) {
      CLASSNAME c = new CLASSNAME();
      c.setVisible(true);
   }

   /**
    * Events:  action
    * Method:  actionPerformed
    */
   void menuItemExit_actionPerformed(java.awt.event.ActionEvent e0) {
      // add code here
      ExitDialog dialog=new ExitDialog(this);
      dialog.setVisible(true);
      
   }

   /**
    * Events:  window
    * Method:  windowClosing
    */
   void CLASSNAME_windowClosing(java.awt.event.WindowEvent e0) {
      // add code here
      menuItemExit_actionPerformed(null);
      
   }

   /**
    * Events:  action
    * Method:  actionPerformed
    */
   void menuItemAbout_actionPerformed(java.awt.event.ActionEvent e0) {
      // add code here
      AboutDialog dialog=new AboutDialog(this);
      dialog.setVisible(true);
      
   }

   /**
    * Events:  action
    * Method:  actionPerformed
    */
   void menuItemOpen_actionPerformed(java.awt.event.ActionEvent e0) {
      try {
          // OpenFileDialog create and show modal
          FileDialog openFileDialog;
          openFileDialog = new FileDialog(this,"Open",FileDialog.LOAD);
          openFileDialog.setModal(true);
          openFileDialog.setVisible(true);
      } catch (Exception e) {
      }
   }

}

class CLASSNAME_WindowAdapter extends WindowAdapter {
   CLASSNAME adaptee;
   CLASSNAME_WindowAdapter(CLASSNAME adaptee) {
      this.adaptee=adaptee;
   }
   public void windowClosing(java.awt.event.WindowEvent e0) {
      adaptee.CLASSNAME_windowClosing(e0);
   }
}

class CLASSNAME_menuItemOpen_ActionAdapter implements ActionListener {
   CLASSNAME adaptee;
   CLASSNAME_menuItemOpen_ActionAdapter(CLASSNAME adaptee) {
      this.adaptee=adaptee;
   }
   public void actionPerformed(java.awt.event.ActionEvent e0) {
      adaptee.menuItemOpen_actionPerformed(e0);
   }
}


class CLASSNAME_menuItemExit_ActionAdapter implements ActionListener {
   CLASSNAME adaptee;
   CLASSNAME_menuItemExit_ActionAdapter(CLASSNAME adaptee) {
      this.adaptee=adaptee;
   }
   public void actionPerformed(java.awt.event.ActionEvent e0) {
      adaptee.menuItemExit_actionPerformed(e0);
   }
}


class CLASSNAME_menuItemAbout_ActionAdapter implements ActionListener {
   CLASSNAME adaptee;
   CLASSNAME_menuItemAbout_ActionAdapter(CLASSNAME adaptee) {
      this.adaptee=adaptee;
   }
   public void actionPerformed(java.awt.event.ActionEvent e0) {
      adaptee.menuItemAbout_actionPerformed(e0);
   }
}
