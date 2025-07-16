# 🚀 After Install

**After Install** is an opinionated post-installation tool for **Debian Trixie**, designed to streamline and personalize your Linux setup—both in the terminal and on the GNOME desktop. It applies sensible defaults, installs essential tools, and delivers a clean, consistent environment that’s ready to use from the start.

## 📥 Installation

> ⚠️ **Requirements:**  
> - Must be run by a user with **sudo** privileges  
> - **Do not** run as the root user  

### Using `curl` (recommended)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kenguru33/after-install/main/bootstrap.sh)"
```

### Or, if you prefer `wget`

```bash
wget https://raw.githubusercontent.com/kenguru33/after-install/main/bootstrap.sh -O /tmp/bootstrap.sh && bash /tmp/bootstrap.sh
```

## ✨ Features

### 🖥️ Shell & Theme

- ⚙️ ZSH powered by Oh-My-Zsh  
- 🌟 Minimal, fast Starship prompt  
- 🎨 Beautiful Catppuccin color scheme  

### 🧰 Terminal Tools

- 🐙 Git and related essentials  
- 🔧 Additional tools (coming soon)  

### 🧩 GNOME Extensions & Configuration

- 🪟 Tiling Shell for window management  
- 💫 Blur My Shell for visual polish  
- 🎨 Papirus icon theme  
- 👤 Gravatar-based user profile image  
- 🖼️ Wallpaper and UI customization  
- 📦 Adds trusted third-party APT sources  

### 📦 Applications

- 🐱 [Kitty Terminal](https://sw.kovidgoyal.net/kitty/) – fast, GPU-based terminal  
- 🧱 [BlackBox Terminal](https://apps.gnome.org/BlackBox/) – sleek GTK-based terminal  
- 🧑‍💻 [Visual Studio Code](https://code.visualstudio.com/) – versatile code editor  

---

> 🛠 **After Install** helps you go from fresh Debian to a fully personalized system—fast, clean, and ready for work.
