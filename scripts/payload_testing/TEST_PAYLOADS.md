# SIP Server Test Payloads

## Prerequisites

Build and start the server:

    c3c build
    build/c3-sip-server &

## Quick Start

    # Send an INVITE (converts LF -> CRLF automatically)
    scripts/payload_testing/send_payload.sh INVITE

    # Send other method examples
    scripts/payload_testing/send_payload.sh BYE
    scripts/payload_testing/send_payload.sh REGISTER
    scripts/payload_testing/send_payload.sh OPTIONS

    # For a different host
    scripts/payload_testing/send_payload.sh INVITE 192.168.1.3 5060

## Payload Files

All payloads are in `scripts/payload_testing/payloads`. They use `\n` line endings;
`send_payload.sh` converts them to `\r\n` for SIP-compliance. 

| File | Method | Purpose |
|---|---|---|
| `INVITE.txt` | INVITE | Basic call setup |
| `INVITE_SDP.txt` | INVITE | Call setup with SDP body |
| `ACK.txt` | ACK | Acknowledge final response |
| `BYE.txt` | BYE | Terminate a call |
| `CANCEL.txt` | CANCEL | Cancel a pending INVITE |
| `REGISTER.txt` | REGISTER | Register a user agent |
| `OPTIONS.txt` | OPTIONS | Query server capabilities |
| `MESSAGE.txt` | MESSAGE | Instant message |
| `INFO.txt` | INFO | Mid-call signalling (DTMF) |
| `SUBSCRIBE.txt` | SUBSCRIBE | Subscribe to events |
| `NOTIFY.txt` | NOTIFY | Event notification |
| `REFER.txt` | REFER | Transfer a call |
| `PUBLISH.txt` | PUBLISH | Publish presence |
| `UPDATE.txt` | UPDATE | Modify session parameters |
| `MALFORMED.txt` | INVITE | Missing required headers |

## Expected Server Behaviour

### All Methods

The server parses the request line and extracts: Via, From, To,
Call-ID, and CSeq headers. It always sends:

| Response | Status | Notes |
|---|---|---|
| `100 Trying` | Provisional | Sent for every valid request |

### INVITE Only

After `100 Trying`, the server sends:

| Response | Status | Notes |
|---|---|---|
| `100 Trying` | Provisional | Stop retransmissions |
| `180 Ringing` | Provisional | Alerting user |
| `200 OK` | Final | Call accepted |

### Other Methods (ACK, BYE, REGISTER, etc.)

Only `100 Trying` is sent. Full response handling for these
methods is not yet implemented.

### Malformed Requests

Requests missing Via, From, To, Call-ID, or CSeq still receive
`100 Trying` but the missing headers will be empty in the response
(`100 Trying` followed by blank Via/From/To lines).

## Manual Usage (without the script)

    # Send a payload with proper CRLF line endings:
    sed 's/$/\r/' scripts/payload_testing/payloads/INVITE.txt | nc -w 3 127.0.0.1 5060

    # Or using python:
    python3 -c "
    import socket
    with open('scripts/payload_testing/payloads/INVITE.txt') as f:
        data = f.read().replace('\n', '\r\n')
    s = socket.socket()
    s.settimeout(3)
    s.connect(('127.0.0.1', 5060))
    s.sendall(data.encode())
    print(s.recv(4096).decode())
    s.close()
    "
