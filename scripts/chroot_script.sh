#!/bin/bash
# Mount necessary filesystems
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs dev /dev

# Run Ansible in chroot
cd /root/ansible-setup
ansible-playbook playbook.yml --tags post_install

# Cleanup
umount -R /proc /sys /dev
