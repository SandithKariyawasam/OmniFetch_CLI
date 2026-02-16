# ⚡ OmniFetch CLI v1.3

**OmniFetch CLI** is a lightweight, continuous, and highly robust PowerShell-based command-line tool for downloading media directly from the web. 

Whether you are pulling direct files from a server or extracting hidden streaming video from complex websites, OmniFetch handles it all in a single, terminal-based interface—no browsers, extensions, or heavy GUI applications required.

## ✨ Features

* **🔄 Continuous Operation:** Runs in a persistent loop. Download multiple files back-to-back without restarting the script.
* **🔀 Smart Dual-Engine System:**
  * **[Mode 1] Direct Engine:** Native PowerShell engine for direct links (`.mp4`, `.zip`, `.exe`). Features real-time progress bars, speed monitoring, and **resumable downloads** for interrupted network connections.
  * **[Mode 2] Web Video Engine:** Integrated `yt-dlp` backend to extract videos from YouTube, news sites, and social media.
* **🕵️‍♂️ Auto-Sniffer Technology:** Automatically bypasses simple web players (like FluidPlayer) by faking a browser request, scanning the page's HTML, and extracting hidden `.m3u8` master streams.
* **🧠 Auto-MIME Detection:** Automatically detects the correct file type and assigns the proper extension if a URL lacks one.
* **📁 Auto-Organization:** Saves all files neatly into an auto-generated `Downloads` folder.

## 🛠️ Prerequisites & Installation

OmniFetch CLI is written in plain PowerShell, but its **Web Video (Mode 2)** relies on two open-source engines. 

### 1. Download the Script
Save `OmniFetch_CLI.ps1` to a dedicated folder on your computer (e.g., `C:\OmniFetch\`).

### 2. Download the Required Engines
For OmniFetch to process complex websites and merge audio/video streams, you must place these two `.exe` files in the **exact same folder** as your script:
1. **yt-dlp.exe:** [Download the latest release here](https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe)
2. **ffmpeg.exe:** [Download the essential build here](https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-essentials.7z) *(Extract the `.7z` file, open the `bin` folder, and copy `ffmpeg.exe` to your OmniFetch folder).*

🚀 Usage
Right-click OmniFetch_CLI.ps1 and select Run with PowerShell.
(Note: If scripts are disabled on your system, open PowerShell as Admin and run Set-ExecutionPolicy RemoteSigned -Scope CurrentUser).

Paste your URL into the prompt.

Select your Mode:
* Type 1 if you are downloading a direct file link (ends in .mp4, .jpg, .zip, etc.).
* Type 2 if you are pasting a website link that contains a video (YouTube, embedded players, etc.).
* OmniFetch will handle the rest! Type exit when you are done to close the tool.

🛟 Troubleshooting: The "F12 Method"
If the Auto-Sniffer fails to find a video on a heavily protected site, you can extract the stream manually:

Open the video page in your browser.
* Press F12 to open Developer Tools and go to the Network tab.
* Type m3u8 in the filter box, refresh the page (F5), and play the video.
* Right-click the .m3u8 file that appears and select Copy Link Address.
* Paste that link into OmniFetch and select Mode 2.

📝 Supported File Types (Direct Mode)
* Videos: .mp4, .webm, .mkv, .mov, .avi
* Images: .jpg, .png, .gif, .webp, .svg
* Audio: .mp3, .wav, .ogg, .aac, .flac
* Docs/Arch: .pdf, .zip, .rar, .txt
(Mode 2 supports virtually any video format provided by the host website).
