Motivation
==========

Modern computers have many network interfaces -- Wifi, Ethernet, Bluetooth, Thunderbolt, etc.
The interfaces are all standardized, and interoperate more or less universally.
Standards have evolved, but new devices are still compatible with devices that are more than 20 years old.

And yet, I just can't figure out how to send a file from one computer to another.

I have a brand new Mac, and a brand new machine from Microsoft, and I can't send files from one to the other.

There are so many protocols that could accomplish the task. There's AFP, SMB, NFS, HTTP(S), (S)FTP and SSH.
But somehow, even though most modern OSes support a bunch of them, there's always some compatibility issue.
After 20 minutes of frustrated googling I always end up using a USB thumb drive to copy files.

A few years ago, Apple introduced Airdrop to solve this once and forever, as long as you used only Apple devices.
But they messed it up. When you activate Airdrop, you have a 50% chance of seeing the device you want to send to,
even if it is on the same Wifi network.

The only protocol that's universally supported is HTTP(S), through web browsers, as long as you are only interested
in downloading files from a web server. (However, new sites have started using certificates that are no longer accepted by old devices)

But even if your computers speak the same protocol, the experience is sub-par:


- Discoverability is unreliable. Devices show up and disappear randomly.
  When a computer goes to sleep, it may disappear, or linger in your sidebar, and you might be able to still connect to it or not.

- As soon as more than one user accesses a network drive, permission issues are inevitable.

- Security is questionable. Many protocols are unencrypted, and even when they use encryption, there is no way to authenticate that your peer is who they say they are.

- Even if the protocols themselve are secure (SFTP), they do not have a way to verify integrity or trace the origin of transferred files.
  So even in the best case, you have to rely on external tools for authenticating files.

- People rarely set up secondary sharing accounts, so typically they share their account password with peers, and grant access to the entire home driectory, or even the entire hard drive.
  This means that people expose a lot more information that they would like.


The goal of this app is to solve all of these issues.

- Secure by default. Devices are authenticate eachother with public key cryptography.
  Network traffic is encrypted, preventing passive eavesdropping.
  When an attacker tries to impersonate another device, it shows up as a new, unknown device.

- No passwords. All crypto based on public keys. Easy to grant access to others, hard to leak data.

- Simple Key verification with QR Codes / base58 / hex representations of keys.

- Universal support. Simple protocol means it's easy to write apps for any OS.
  First party apps are aim to be compatible with ancient versions (eg. we even support macOS 10.6 on 32bit)

- Crypto is optional so we can potentially support even very old computers (eg. my old Macintosh Color Classic) or microcontrollers (eg. Arduino)

- Really easy and reliable discovery. Other peers on the LAN appear instantly and inform others of state changes (eg. shutting down, going to sleep).

- High performance. It should not take ages to transfer a folder just because it contains a lot of very small files.

- Adaptible: New interfaces should be detected immediately as they become available.
  If a transfer over Wifi is slow, plugging in an ethernet cable should speed it up instantly.
  No user interaction should be necessary beyond plugging in a cable.





Notes
=====

SO_REUSEADDR and SO_REUSEPORT
-----------------------------

If we set SO_REUSEADDR and SO_REUSEPORT, we can bind multiple UDP sockets to te same port & address.

This only works if every process sets those options. If a process called bind() without these options before, we wont be able to bind() any more.

It seems that setting SO_REUSEADDR alone is not sufficient, we have to set SO_REUSEPORT as well.

UDP messages sent to the broadcastaddr with the SO_BROADCAST option will then be delivered to all listeners.

However, UDP messages sent to a non-broadcast address will only be delivered once. In my testing the message goes only to the first socket that called bind().

Conclusion: We need to make sure to use a port that nobody else is using. If another process is already listening on the port, we will run into trouble.

Multiple clients on one machine?
We could support multiple clients on one machine by using two ports. We bind to the boradcast port with SO_REUSEADDR and SO_REUSEPORT so we can receive broadcast messages.
We bind on a second, randomized port that we use as source for all outgoing messages. Any response to our broadcast messages are received on that second port.


PEER DISCOVERY PROTOCOL
=======================

All UDP messages start with a "magic number", which makes random collisions much less likely.


4 bytes   Magic Number "\03PDP"

1 byte    Length of Header Data

1 byte    'A': Announce presence or new state (eg. computer sleeping)
          'S': Scan: Request announce messages from the recipient (or from everyone).
               Optionally includes all the info from an announce message in the same packet.
          'C': Command.

1 byte    Flags

          0x01 Supports v1 protocol
          0x02 Has Ed25519 Key + Signature
          0x04 Reserved
          0x08 Reserved
          0x10 Reserved
          0x20 Reserved
          0x40 Reserved
          0x80 Reserved

1 byte    Extra Flags ???

          0x01 Reserved
          0x02 Reserved
          0x04 Reserved
          0x08 Reserved
          0x10 Reserved
          0x20 Reserved
          0x40 Reserved
          0x80 Reserved

Key/Value Section

1 byte    Length Of Key = Lk
Lk bytes  Key
1 byte    Length of Value = Lv
Lv bytes  Value

...

Keys:

N         Device Name
M         Device Model
p         TCP Port Number
T         Request Token (will be included in responses)
K         32 byte Ed25519 Public Key + 64 byte Signature (must be last value)









UDP Protocol
------------

- Listen for scan messages. Add services that we are told about, and reply to scan messages


- If we offer a service, whenever the computer wakes from sleep, or whenever properties are changed: Broadcast an announcement message


- When the app is opened, or when the user presses the scan button: Broadcast a scan message


Sending Files via TCP
---------------------

 -  Server listens for TCP connections.

<-> Establish an authenticated, encrypted connection

 -> Send file metadata to server

    Server verifies if client is allowed to send, closes connection if not

 -> Send file data to server

If a transfer fails, the server may later connect to the client to retry.

Messages
--------

- Announcement Message (spontaneous or in reply to scan messages)

- Scan Message

- Error Messages ?





Name Brainstorming
==================

    Six Things
    Six Box
    Sextett -> "sex" prefix may cause problems
    Oktett 
    Sixpak -> too masculin, not generic enough
    6pak
    Sixbag
    Sechser Tragerl
    6 Board
    6er Brettl
    Pinwand
    Lanbox
    Lanboard
    Lancrate
    Lanstack
    Langrid
    LanDrop -> es gibt ein Github Repo, das Tool scheint etwas ähnliches zu tun, scheint aber obsolet
    Localbox / Globalbox
    Lankiste
    Netstick
    Airstick
    Airdrive
    Landrive
    Airfolder
 => Netzablage <=
    Netrack
    Lanrack
    Netshelf
    Netzregal
    Netstorage
    Pocket
    Store
    tray
    depot
    magazine
    Lager Dump
    Ablage
    Octet
 => Oktett <=
    Octdoc
    Okidok
    Okidoki



