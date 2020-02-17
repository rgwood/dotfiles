# Networking

https://www.digitalocean.com/community/tutorials/understanding-ip-addresses-subnets-and-cidr-notation-for-networking

IPv4 has a concept of _classes_, the address space is divided into 5 classes (A, B, C, D, E). No longer really used in practice.

## Expressing subnets

Can use CIDR to indicate which bits of the prefix are significant. Can also use a netmask.

In examples we will use the loopback range of 127.0.0.0 to 127.255.255.255.

### CIDR

127.0.0.0/8

/8 indicates that only the first 8 bits are significant

### Netmask

Address: 127.0.0.0

Netmask: 255.0.0.0 in decimal, or 1111 1111.0000 0000.0000 0000.0000 0000 in binary

Netmask shows which 

## Reserved IP address ranges

https://en.wikipedia.org/wiki/Reserved_IP_addresses

Some of the most common ones:

* Loopback range (connect to self): 127.0.0.0/8
* Private network: 10.0.0.0/8, 192.168.0.0/16
* Link-local (between 2 hosts, no DHCP server): 169.254.0.0/16

## General port troubleshooting

What's listening on port 5001? `lsof -i :PORT_NUM` to the rescue.

```
lsof -i :5001
COMMAND  PID       USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
ports   6224 reillywood  153u  IPv4 0x8ae410bf4cd93f05      0t0  TCP localhost:commplex-link (LISTEN)
ports   6224 reillywood  154u  IPv6 0x8ae410bf48ea98d5      0t0  TCP localhost:commplex-link (LISTEN)
```

Then `ps -p PID` to show more deets about PID 6224:

```
ps -p 6224
  PID TTY           TIME CMD
 6224 ttys005    0:00.77 /Users/reillywood/source/temp/ports/bin/Debug/netcoreapp3.0/ports
```

## scp for remote filecopy

`scp your_username@remotehost:foo.txt /some/local/directory`

## VPN

OpenVPN is pretty easy to use from a CLI. Get a `.ovpn` config file from provider, then:

`sudo openvpn --config "Config.ovpn" &`

Can save username/password in a text file (separated by newline) and then specify the filename in the .ovpn config like:

`auth-user-pass myUserNameAndPassword.txt`

## Get external IP address quickly

`curl ifconfig.me`