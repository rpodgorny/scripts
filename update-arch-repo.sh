set -x

mkdir /tmp/arch-repo
sshfs podgorny.cz:arch-repo /tmp/arch-repo
cd /tmp/arch-repo
rm rpodgorny.db.*
repo-add rpodgorny.db.tar.xz *.pkg.*
cd -
fusermount -u /tmp/arch-repo
rmdir /tmp/arch-repo
