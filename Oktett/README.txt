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
T         Request Token (will be included in responses)
K         32 byte Ed25519 Public Key + 64 byte Signature (must be last value)









UDP Protocol
------------

- Listen for scan messages. Add services that we are told about, and reply to scan messages


- If we offer a service, whenever the computer wakes from sleep, or whenever properties are changed: Broadcast an announcement message


- When the app is opened, or when the user presses the scan button: Broadcast a scan message


TCP Service ?
-------------

- Listen for connections. Respond with an announce message?

- After the announce message, wait for more commands / messages


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



