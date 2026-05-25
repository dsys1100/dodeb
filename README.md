# What is Dodeb?

It's simple. Docker+Debian. I wanted to call this project "Minideb", but that name is already [taken](https://github.com/bitnami/minideb).  
Here’s a fun fact that Russian speakers will get-the word "додеп" popped into my head, which is why I chose this title :)

## How to use this?

**Internet is required**, because is netinstall iso.  
The initial steps are the same as for a standard Debian installation. There is no language selection because the UI must be in English, keyboard is us. Enter proxy if necessary, create user, partition disk. Reboot after downloading and installing OS.  
My tweaks in this "OS": Grub timeout = 1 sec, only needed drivers in initramfs, and a Docker included.

# Why does it exist?

So, here’s the deal. I need the most **minimal** system possible to use as a **Docker host**. My options are:
- Specialized OSes: 
  - FCOS and similar systems are immutable. You can’t install anything on them, and they take up a lot of space.
  - [Lightwhale](https://lightwhale.asklandd.dk/) is a great project; I used it before Debian. It takes up very little space, but I don’t like that you can’t install it - you can only burn it to an external drive and use the internal drive for Docker data.
- Alpine with Docker - no matter how hard I tried to set it up, Docker never worked properly. Either it was a nightmare with cgroups (on virt variant and standart), or it just couldn’t connect to the socket. Basically, I got fed up with it.
- Default Debian with Docker - I usually use it, but I’m too lazy to remove unnecessary packages after installation.

I haven't found any current projects that use Docker-only binaries (or that and as little of the rest as possible), take up little space, and behave like regular systems. Maybe I didn't look hard enough - who knows.

Anyway, take a look at my repositories. I mostly created them just for fun, and because I enjoy automation and tinkering with OSes.

# How is it created?

It’s all straightforward - check out Workflows. Downloading the minimal installer, which is under 100 MB, editing the installation script so that the necessary packages are installed on the final system, do a bit of system configuration, and removing any unnecessary packages. Personally, I only need Docker and coreutils, but sometimes I need to install something else, and in this case I can easily do so, since it’s just a slightly stripped-down version of the default Debian system.