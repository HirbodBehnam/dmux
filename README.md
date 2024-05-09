# dmux
Manage your docker containers.

## What?
dmux or Docker MUltiplXer is a script that managers docker containers which are intended for compiling software.
It works by starting a docker container with current directory mounted as the working directory of docker and giving
you a bash shell inside the container. With this, you can simply execute commands which are intended for compiling the software in the docker, isolated from your host.

## How?
It simply works by running `docker run bash` with a container name and current directory mounted as working directory.

For example, one can use these commands to compile a rust program.
```
root@crow:~# git clone https://github.com/HirbodBehnam/lossy_link
root@crow:~# cd lossy_link/
root@crow:~/lossy_link# dmux rust
root@dmux-rust:/workdir# cargo build --release
root@dmux-rust:/workdir# file target/release/lossy_link
target/release/lossy_link: ELF 64-bit LSB pie executable, ARM aarch64, ...
root@dmux-rust:/workdir# exit
root@crow:~/lossy_link# file target/release/lossy_link
target/release/lossy_link: ELF 64-bit LSB pie executable, ARM aarch64, ...
```

## Installing

Just copy the script to somewhere in your path and make it executable.
```bash
curl -o /usr/bin/dmux https://github.com/HirbodBehnam/dmux/raw/master/dmux.sh
chmod +x /usr/bin/dmux
dmux
```