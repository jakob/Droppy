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



Message Protocol
================

All UDP messages start with a "magic number", which makes random collisions much less likely.

General format:

7 bytes: magic number
1 byte: message type


Messages
--------


 => Greeting and introduction message
    
    Magic Number
    7 bytes

    Message Type: 'I'
    1 byte

    uint16 Minimum Compatible Protocol Version
    2 bytes

    uint16 Current Protocol Version
    2 bytes

    UUID
    16 bytes

    TCP Listen Port
    2 bytes

    Short Name
    1 byte (length) + UTF8 bytes

    Device Type
    1 byte (length) + UTF8 bytes

    Capabilities
    1 byte flag
    0x1 Offers services



OKTETT PEER DISCOVERY PROTOCOL
==============================


Oktett/Q
--------

Query message.

Requests information about the current state of all peers on the network.

Repeat this message several times.


Oktett/I
--------

Inform peers on the network about my current state.

Repeat this message until an ack arrives.


Oktett/Ack
----------

Acknowledges receipt of something.









UDP Protocol
------------

- Listen for greeting messages. Add services that we are told about, and reply to greetings that have the "Wants TCP reply" flag set


- If we offer a service, whenever the computer wakes from sleep, or whenever properties are changed: Broadcast a greeting message


- When the app is opened, or when the user presses the scan button: Broadcast a greeting message with the "Wants TCP reply"


TCP Service
-----------

- Listen for connections. Respond with a greeting message?

- After the greeting message, wait for more commands / messages


Messages
--------

- Identification Message (spontaneous or in reply to identification request)

- Identification Request Message

- Error Message





Name Brainstorming
==================

    Six Things
    Six Box
    Sextett -> "sex" prefix may cause problems
    Oktett -> too masculin, not generic enough
    Sixpak
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



