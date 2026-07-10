
## SIP Lifecycle

![](SIP-Dialog.jpg)

Extract from RFC 3261
```
                     site-A.com  . . .  site-B.com
                  .    proxy              proxy     .
               .                                       .
       Alice's  . . . . . . . . . . . . . . . . . . . .  Bob's
      softphone                                        SIP Phone
         |                |                |                |
         |    INVITE F1   |                |                |
         |--------------->|    INVITE F2   |                |
         |  100 Trying F3 |--------------->|    INVITE F4   |
         |<---------------|  100 Trying F5 |--------------->|
         |                |<-------------- | 180 Ringing F6 |
         |                | 180 Ringing F7 |<---------------|
         | 180 Ringing F8 |<---------------|     200 OK F9  |
         |<---------------|    200 OK F10  |<---------------|
         |    200 OK F11  |<---------------|                |
         |<---------------|                |                |
         |                       ACK F12                    |
         |------------------------------------------------->|
         |                   Media Session                  |
         |<================================================>|
         |                       BYE F13                    |
         |<-------------------------------------------------|
         |                     200 OK F14                   |
         |------------------------------------------------->|
         |                                                  |

         Figure 1: SIP session setup example with SIP trapezoid
```

A dialogue is a record of all SIP transactions (or, events) that occur during some interaction (where an interaction may be a phone call).

A dialogue is typically made up of the following transactions:

1. INVITE 
2. TRYING
3. RINGING
4. OK
5. ACK
6. BYE

Additionally, a SIP session may invoke either of the following:

1. OK
2. CANCEL

