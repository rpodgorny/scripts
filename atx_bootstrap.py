#!/usr/bin/python3

import os
import platform
import subprocess
import sys


def load_env():
    env_file = ".env"
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, value = line.split("=", 1)
                    os.environ.setdefault(key, value)


load_env()


def get_env(name):
    value = os.environ.get(name)
    if not value:
        print(f"Error: Environment variable {name} is not set.", file=sys.stderr)
        sys.exit(1)
    return value


# TODO: find a better name
def xcall(cmd, silent=False):
    if not silent:
        print(f">>> {cmd}")
        stdout = None
    else:
        stdout = subprocess.DEVNULL
    return subprocess.call(cmd, shell=True, stdout=stdout)


def call(cmd, silent=False):
    if not silent:
        print(f">>> {cmd}")
        stdout = None
    else:
        stdout = subprocess.DEVNULL
    return subprocess.check_call(cmd, shell=True, stdout=stdout)


# not tested
#def sudo():
#    call("sed -i 's/%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' ")


def remoteadmin():
    if xcall("id -u remoteadmin", silent=True) == 0:
        print("User remoteadmin already exists, skipping creation")
        return
    call("useradd -u 1010 -m -G sudo -s /bin/bash remoteadmin")
    password = get_env("ATX_REMOTEADMIN_PASSWORD")
    call(f"echo 'remoteadmin:{password}' | chpasswd")


def apt_sources(codename):
    with open("/etc/apt/sources.list.d/asterix.list", "w") as f:
        f.write(f"""deb https://deb.asterix.cz/{codename} {codename} main
""")
    call(f"wget -qO - https://deb.asterix.cz/{codename}/asterix.key | gpg --dearmor >/etc/apt/trusted.gpg.d/asterix.gpg")

    if codename == "noble":
        # for python3.11
        call("add-apt-repository -y ppa:deadsnakes/ppa")


def sshd():
    call("apt install -y openssh-server")
    call("systemctl enable ssh")
    call("systemctl start ssh")


def openvpn():
    call("apt install -y openvpn")
    # TODO: finish openvpn


def wireguard():
    pass
    # TODO: finish wireguard


def samba():
    call("apt install -y samba")

    with open("/etc/samba/smb.conf", "w") as f:
        f.write("""[global]
  workgroup = WORKGROUP
  netbios name = kukurice
  server string = ATX Samba Server
  security = user
  map to guest = Bad User
  log file = /var/log/samba/log.%m
  max log size = 50
  dns proxy = no

[comm]
  path = /atx300/comm
  browsable = yes
  writable = yes
  guest ok = no
  read only = no
""")

    call("systemctl enable smbd nmbd")
    call("systemctl start smbd nmbd")


def faddnsc():
    call("apt install -y faddnsc")

    with open("/etc/faddnsc.conf", "w") as f:
        f.write("""[General]
Url=http://faddns.asterix.cz
""")

    call("systemctl enable faddnsc")
    call("systemctl start faddnsc")


def x11vnc():
    call("apt install -y x11vnc")

    vnc_pass = get_env("ATX_VNC_PASSWORD")
    vnc_view_pass = get_env("ATX_VNC_VIEW_PASSWORD")

    with open("/etc/systemd/system/x11vnc.service", "w") as f:
        f.write(f"""[Unit]
Description=Start x11vnc at startup.
After=display-manager.service
Requires=display-manager.service

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc \
  -auth guess \
  -forever \
  -loop \
  -repeat \
  -shared \
  -passwd {vnc_pass} \
  -viewpasswd {vnc_view_pass} \
  -rfbport 5900 \
  -display :0
Restart=always
RestartSec=2

[Install]
WantedBy=graphical.target
""")
    #  -rfbauth /etc/x11vnc.pass \

    #call("x11vnc -storepasswd atx438c /etc/x11vnc.pass")
    #call("x11vnc -storepasswd atx438w /etc/x11vnc.pass -append")
    #call("sudo chmod 600 /etc/x11vnc.pass")

    call("sudo systemctl enable x11vnc.service")
    call("sudo systemctl start x11vnc.service")


def locale():
    with open("/etc/locale.gen", "w") as f:
        f.write("""cs_CZ.UTF-8 UTF-8
en_US.UTF-8 UTF-8
""")
    call("locale-gen")

    # TODO: solve the USE_DPKG stuff
    call("apt install -y localepurge")
    with open("/etc/locale.nopurge", "w") as f:
        f.write("""#USE_DPKG
MANDELETE
DONTBOTHERNEWLOCALE
SHOWFREEDSPACE

cs
cs_CZ.UTF-8
en
en_US.UTF-8
""")
    call("localepurge")
    # TODO: this is probably not enough - we also need to regenerate /etc/dpkg/dpkg.cfg.d/50localepurge file


def main():
    if os.geteuid() != 0:
        print("Error: This script must be run as root.", file=sys.stderr)
        sys.exit(1)

    os.environ["DEBIAN_FRONTEND"] = "noninteractive"

    codename = subprocess.check_output("cat /etc/os-release | grep UBUNTU_CODENAME | cut -d= -f 2", shell=True).decode().strip()
    if not codename:
        codename = subprocess.check_output("cat /etc/os-release | grep VERSION_CODENAME | cut -d= -f 2", shell=True).decode().strip()
    print(f"{codename=}")
    assert codename in {"noble", "trixie"}, codename

    arch = platform.machine()
    assert arch in {"aarch64", "x86_64"}, arch

    hostname = input("new hostname: ")
    if hostname:
        call(f"hostnamectl hostname {hostname}")
    else:
        print("Keeping current hostname")

    remoteadmin()

    # TODO: select nif iface
    # nmcli connection modify 90ca662e-79d5-3d33-ac54-786fd8cc8fc4 connection.id IOR
    # nmcli connection modify IOR ipv4.method manual ipv4.addresses 192.168.100.199/24
    # revert to dhcp: ipv4.method auto

    apt_sources(codename)

    call("apt update")

    # cleanup
    call("apt remove -y rpi-imager")  # TODO: only do this on raspberry pi?
    call("apt remove -y build-essential")
    call("apt -y autoremove")
    # TODO: maybe get rid of /usr/share/doc and others: https://askubuntu.com/questions/129566/remove-documentation-to-save-hard-drive-space

    locale()

    openvpn()
    wireguard()
    faddnsc()
    sshd()

    # TODO: for samba sharing - create by installing atx400-base or something
    call("mkdir -p /atx300/comm")

    samba()

    # TODO: add us kbd layout

    x11vnc()

    # TODO: hacky shit for atx programs
    call("mkdir -p /atx300/comm/dis_man /atx300/comm/man_dis")
    call("mkdir -p /atx300/log")
    call("chown -R o:o /atx300")

    # TODO: install atx400


main()
