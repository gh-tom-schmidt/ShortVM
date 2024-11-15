# **ShortVM**  
A lightweight shell script for using QEMU virtualization with short and simple commands.

---

## **The `v` Script**  
This script is currently under development. Bugs will be fixed as they arise during use.  
New features will be added based on necessity and feedback.

---

## **The Firefox Extension**  
The Firefox extension is a Work in Progress (WIP) and will be updated in future releases.

---

## **Installation**  
Follow these steps to install and set up the script:  

1. **Place the script in a desired folder.**  
2. **Make the script executable:**  
   ```bash
   (sudo) chmod +x /path/to/script
   ```
3. **Add the script to your `PATH`:**  
   - Open your `~/.zshrc` (or `~/.bashrc`, depending on your shell).  
   - Add the following line:  
     ```bash
     export PATH="$HOME/Scripts:$PATH"
     ```  
   Replace `"$HOME/Scripts"` with the directory where your script is located.  

4. **Reload your shell configuration:**  
   ```bash
   source ~/.zshrc  # or source ~/.bashrc
