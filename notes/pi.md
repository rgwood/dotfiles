## Raspberry Pi

### Temperature readings

GPU: `vcgencmd measure_temp`
CPU: `cat /sys/class/thermal/thermal_zone0/temp` (Celsius, divide by 1000)

### Config file locations

Samba: `/etc/samba/smb.conf`
Transmission: `~/.config/transmission-daemon/settings.json`

## Backups
`crontab -e`
`0 13 * * * rsync /etc/samba/smb.conf /mnt/external/PiBackup/Daily/`

### Disks

List block devices:
`sudo lsblk -o UUID,NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL,MODEL`
or just `sudo lsblk -f`

Mount LUKS encrypted disk at `/dev/sda` manually:
`sudo cryptsetup luksOpen /dev/sda DISKNAME`
then
`sudo mount /dev/mapper/DISKNAME /mnt/DISKNAME`

Can automatically decrypt LUKS disk on startup by editing crypttab https://www.golinuxcloud.com/mount-luks-encrypted-disk-partition-linux/
Then the usual in /etc/fstab to mount it