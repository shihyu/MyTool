import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

/**
 * 
 * 
 * @author 
 * @version 
 */
public class CLASSNAME extends JFrame

{
   ImageIcon iconAbout = new ImageIcon(CLASSNAME.class.getResource("images/about.gif"));
   JMenuItem menuItemAbout = new JMenuItem();
   JMenu menuItemHelp = new JMenu();
   ImageIcon iconPaste = new ImageIcon(CLASSNAME.class.getResource("images/paste.gif"));
   JMenuItem menuItemPaste = new JMenuItem();
   ImageIcon iconCopy = new ImageIcon(CLASSNAME.class.getResource("images/copy.gif"));
   JMenuItem menuItemCopy = new JMenuItem();
   ImageIcon iconCut = new ImageIcon(CLASSNAME.class.getResource("images/cut.gif"));
   JMenuItem menuItemCut = new JMenuItem();
   JMenu menuEdit = new JMenu();
   JMenuItem menuItemExit = new JMenuItem();
   JMenuItem menuItemSave_As = new JMenuItem();
   ImageIcon iconSave = new ImageIcon(CLASSNAME.class.getResource("images/save.gif"));
   JMenuItem menuItemSave = new JMenuItem();
   ImageIcon iconOpen = new ImageIcon(CLASSNAME.class.getResource("images/open.gif"));
   JMenuItem menuItemOpen = new JMenuItem();
   ImageIcon iconNew = new ImageIcon(CLASSNAME.class.getResource("images/new.gif"));
   JMenuItem menuItemNew = new JMenuItem();
   JMenu menuFile = new JMenu();
   JMenuBar jMenuBar1 = new JMenuBar();
   FlowLayout flowLayoutDefault = new FlowLayout();
   BorderLayout borderLayout1 = new BorderLayout();
   JPanel jPanel1 = new JPanel();
   BorderLayout borderLayout3 = new BorderLayout();
   BorderLayout borderLayout2 = new BorderLayout();
   JToolBar jToolBar1 = new JToolBar();
   JPanel jPanel2 = new JPanel();
   FlowLayout flowLayout1 = new FlowLayout();

   JFileChooser fileChooser=new JFileChooser();
   JButton buttonNew;
   JButton buttonOpen;
   JButton buttonSave;
   JButton buttonCut;
   JButton buttonCopy;
   JButton buttonPaste;
   JButton buttonAbout;
   
   protected void tbAddButtons(JToolBar toolbar) {
       Rectangle bounds = new Rectangle();
       // Bounds for each button
       bounds.x=2;
       bounds.y=2;
       bounds.width=25;
       bounds.height=25;
       // Toolbar separator
       Dimension separator = new Dimension(5,5);
       // Button size
       Dimension buttonsize = new Dimension(bounds.width,bounds.height);

       // New
       buttonNew = new JButton(iconNew);
       buttonNew.setDefaultCapable(false);
       buttonNew.setToolTipText("Create a new document");
       buttonNew.setMnemonic((int)'N');
       toolbar.add(buttonNew);
       buttonNew.setBounds(bounds);
       buttonNew.setMinimumSize(buttonsize);
       buttonNew.setMaximumSize(buttonsize);
       buttonNew.setPreferredSize(buttonsize);
       // Open
       buttonOpen = new JButton(iconOpen);
       buttonOpen.setDefaultCapable(false);
       buttonOpen.setToolTipText("Open an existing document");
       buttonOpen.setMnemonic((int)'O');
       toolbar.add(buttonOpen);
       bounds.x += bounds.width;
       buttonOpen.setBounds(bounds);
       buttonOpen.setMinimumSize(buttonsize);
       buttonOpen.setMaximumSize(buttonsize);
       buttonOpen.setPreferredSize(buttonsize);
       // Save
       buttonSave = new JButton(iconSave);
       buttonSave.setDefaultCapable(false);
       buttonSave.setToolTipText("Save the active document");
       buttonSave.setMnemonic((int)'S');
       toolbar.add(buttonSave);
       bounds.x += bounds.width;
       buttonSave.setBounds(bounds);
       buttonSave.setMinimumSize(buttonsize);
       buttonSave.setMaximumSize(buttonsize);
       buttonSave.setPreferredSize(buttonsize);
       // Separator
       toolbar.addSeparator(separator);
       // Cut
       buttonCut = new JButton(iconCut);
       buttonCut.setDefaultCapable(false);
       buttonCut.setToolTipText("Cut the selection to the clipboard");
       buttonCut.setMnemonic((int)'T');
       toolbar.add(buttonCut);
       bounds.x += bounds.width;
       buttonCut.setBounds(bounds);
       buttonCut.setMinimumSize(buttonsize);
       buttonCut.setMaximumSize(buttonsize);
       buttonCut.setPreferredSize(buttonsize);
       // Copy
       buttonCopy = new JButton(iconCopy);
       buttonCopy.setDefaultCapable(false);
       buttonCopy.setToolTipText("Copy the selection to the clipboard");
       buttonCopy.setMnemonic((int)'C');
       toolbar.add(buttonCopy);
       bounds.x += bounds.width;
       buttonCopy.setBounds(bounds);
       buttonCopy.setMinimumSize(buttonsize);
       buttonCopy.setMaximumSize(buttonsize);
       buttonCopy.setPreferredSize(buttonsize);
       // Paste
       buttonPaste = new JButton(iconPaste);
       buttonPaste.setDefaultCapable(false);
       buttonPaste.setToolTipText("Insert clipboard contents");
       buttonPaste.setMnemonic((int)'P');
       toolbar.add(buttonPaste);
       bounds.x += bounds.width;
       buttonPaste.setBounds(bounds);
       buttonPaste.setMinimumSize(buttonsize);
       buttonPaste.setMaximumSize(buttonsize);
       buttonPaste.setPreferredSize(buttonsize);
       // Separator
       toolbar.addSeparator(separator);
       // About
       buttonAbout = new JButton(iconAbout);
       buttonAbout.setDefaultCapable(false);
       buttonAbout.setToolTipText("Display program information");
       buttonAbout.setMnemonic((int)'A');
       toolbar.add(buttonAbout);
       bounds.x += bounds.width;
       buttonAbout.setBounds(bounds);
       buttonAbout.setMinimumSize(buttonsize);
       buttonAbout.setMaximumSize(buttonsize);
       buttonAbout.setPreferredSize(buttonsize);

       ToolbarActionListener toolbarActionListener=new ToolbarActionListener();

       buttonOpen.addActionListener(toolbarActionListener);
       buttonAbout.addActionListener(toolbarActionListener);
   }

   public CLASSNAME() {
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
      getContentPane().setLayout(borderLayout1);
      this.setJMenuBar(jMenuBar1);


      this.jPanel1.setBounds(0, 0, 784, 614);
      this.jPanel1.setSize(784, 614);
      this.jPanel1.setPreferredSize(new Dimension(717, 614));
      getContentPane().add(jPanel1, "Center");
      this.jPanel2.setBounds(356, 5, 71, 59);
      this.jPanel2.setSize(71, 59);
      this.jPanel2.setPreferredSize(new Dimension(71, 59));
      flowLayout1.setAlignment(FlowLayout.LEFT);
      this.jPanel2.setLayout(flowLayout1);
      getContentPane().add(jPanel2, "North");
      jToolBar1.setBounds(5, 5, 446, 39);
      jToolBar1.setSize(416, 30);
      jToolBar1.setPreferredSize(new Dimension(446, 39));
      this.jPanel2.add(jToolBar1);

      this.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
      this.addWindowListener(new CLASSNAME_WindowAdapter(this));
      menuFile.setText("File");
      jMenuBar1.add(menuFile);
      menuEdit.setText("Edit");
      jMenuBar1.add(menuEdit);
      menuItemHelp.setText("Help");
      jMenuBar1.add(menuItemHelp);
      menuItemNew.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_N, KeyEvent.CTRL_DOWN_MASK));
      menuItemNew.setIcon(iconNew);
      menuItemNew.setMnemonic(78);
      menuItemNew.setText("New");
      menuFile.add(menuItemNew);
      menuItemOpen.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_O, KeyEvent.CTRL_DOWN_MASK));
      menuItemOpen.setIcon(iconOpen);
      menuItemOpen.setText("Open...");
      menuItemOpen.addActionListener(new CLASSNAME_Open_jMenuItem2_ActionAdapter(this));
      menuFile.add(menuItemOpen);
      menuItemSave.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_S, KeyEvent.CTRL_DOWN_MASK));
      menuItemSave.setIcon(iconSave);
      menuItemSave.setText("Save");
      menuFile.add(menuItemSave);
      menuItemSave_As.setText("Save As...");
      menuItemSave_As.addActionListener(new CLASSNAME_Save_As_jMenuItem3_ActionAdapter(this));
      menuFile.add(menuItemSave_As);
      menuFile.addSeparator();
      menuItemExit.setText("Exit");
      menuItemExit.addActionListener(new CLASSNAME_menuItemExit_ActionAdapter(this));
      menuFile.add(menuItemExit);
      menuItemCut.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_X, KeyEvent.CTRL_DOWN_MASK));
      menuItemCut.setIcon(iconCut);
      menuItemCut.setText("Cut");
      menuEdit.add(menuItemCut);
      menuItemCopy.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_C, KeyEvent.CTRL_DOWN_MASK));
      menuItemCopy.setIcon(iconCopy);
      menuItemCopy.setText("Copy");
      menuEdit.add(menuItemCopy);
      menuItemPaste.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_V, KeyEvent.CTRL_DOWN_MASK));
      menuItemPaste.setIcon(iconPaste);
      menuItemPaste.setText("Paste");
      menuEdit.add(menuItemPaste);
      menuItemAbout.setIcon(iconAbout);
      menuItemAbout.setText("About...");
      menuItemAbout.addActionListener(new CLASSNAME_About_jMenuItem8_ActionAdapter(this));
      menuItemHelp.add(menuItemAbout);
   }


   /**
    * Main method
    */
   public static void main(String args[]) {
      try {
         UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
      } catch(Exception e) {
         e.printStackTrace();
      }
      CLASSNAME c = new CLASSNAME();
      c.tbAddButtons(c.jToolBar1);
      c.setVisible(true);
   }

   void Open_jMenuItem2_actionPerformed(java.awt.event.ActionEvent e0) {
      fileChooser.showOpenDialog(this);
   }

   void Save_As_jMenuItem3_actionPerformed(java.awt.event.ActionEvent e0) {
      fileChooser.showOpenDialog(this);
      
   }

   void About_jMenuItem8_actionPerformed(java.awt.event.ActionEvent e0) {
      try {
          JOptionPane.showMessageDialog(this,
                                        "A Basic JFC Application",
                                        "About" ,
                                        JOptionPane.INFORMATION_MESSAGE);
      } catch (Exception e) {
      }
      
   }
   class ToolbarActionListener implements ActionListener {
       public void actionPerformed(ActionEvent event) {
           Object object = event.getSource();
           if (object==buttonOpen) {
               Open_jMenuItem2_actionPerformed(event);
           } else if (object==buttonAbout) {
               About_jMenuItem8_actionPerformed(event);
           }
       }
   }

   void menuItemExit_actionPerformed(java.awt.event.ActionEvent e0) {
      try {
          // Beep
          Toolkit.getDefaultToolkit().beep();
          // Show an Exit confirmation dialog
          int reply = JOptionPane.showConfirmDialog(this,
                                                    "Do you really want to exit?",
                                                    "Exit" ,
                                                    JOptionPane.YES_NO_OPTION,
                                                    JOptionPane.QUESTION_MESSAGE);
          if (reply==JOptionPane.YES_OPTION) {
              // User answered "Yes", so cleanup and exit
              //
              // Hide the frame
              this.setVisible(false);
              // Free system resources
              this.dispose();
              // Exit the application
              System.exit(0);
          }
      } catch (Exception e) {
      }
      
   }

   void CLASSNAME_windowClosing(java.awt.event.WindowEvent e0) {
      menuItemExit_actionPerformed(null);
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

class CLASSNAME_Open_jMenuItem2_ActionAdapter implements ActionListener {
   CLASSNAME adaptee;
   CLASSNAME_Open_jMenuItem2_ActionAdapter(CLASSNAME adaptee) {
      this.adaptee=adaptee;
   }
   public void actionPerformed(java.awt.event.ActionEvent e0) {
      adaptee.Open_jMenuItem2_actionPerformed(e0);
   }
}


class CLASSNAME_Save_As_jMenuItem3_ActionAdapter implements ActionListener {
   CLASSNAME adaptee;
   CLASSNAME_Save_As_jMenuItem3_ActionAdapter(CLASSNAME adaptee) {
      this.adaptee=adaptee;
   }
   public void actionPerformed(java.awt.event.ActionEvent e0) {
      adaptee.Save_As_jMenuItem3_actionPerformed(e0);
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


class CLASSNAME_About_jMenuItem8_ActionAdapter implements ActionListener {
   CLASSNAME adaptee;
   CLASSNAME_About_jMenuItem8_ActionAdapter(CLASSNAME adaptee) {
      this.adaptee=adaptee;
   }
   public void actionPerformed(java.awt.event.ActionEvent e0) {
      adaptee.About_jMenuItem8_actionPerformed(e0);
   }
}
