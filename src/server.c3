module c3_sip_server;

import std::io;
import std::collections;
import std::net;
import std::thread;

const int BUFFSIZE = 4096;

struct ClientTask {
    TcpSocket client;
}

fn String extract_header(String data, String header)
{
    usz header_len = header.len;
    for (usz i = 0; i + header_len < data.len; i++) {
        bool found = true;
        for (usz j = 0; j < header_len; j++) {
            if (data[i + j] != header[j]) { found = false; break; }
        }
        if (!found) continue;

        usz val_start = i + header_len;
        while (val_start < data.len && data[val_start] == ' ') val_start++;

        usz val_end = val_start;
        while (val_end < data.len) {
            if (val_end + 1 < data.len && data[val_end] == '\r' && data[val_end + 1] == '\n') break;
            val_end++;
        }

        return data[val_start:val_end - val_start];
    }
    return "";
}

fn usz build_sip_response(char[] buf, String status_line,
                          String via, String from, String to,
                          String call_id, String cseq)
{
    usz pos = 0;
    pos += io::bprintf(buf[pos..], "SIP/2.0 %s\r\n", status_line)!!.len;
    pos += io::bprintf(buf[pos..], "Via: %s\r\n", via)!!.len;
    pos += io::bprintf(buf[pos..], "From: %s\r\n", from)!!.len;
    pos += io::bprintf(buf[pos..], "To: %s\r\n", to)!!.len;
    pos += io::bprintf(buf[pos..], "Call-ID: %s\r\n", call_id)!!.len;
    pos += io::bprintf(buf[pos..], "CSeq: %s\r\n", cseq)!!.len;
    pos += io::bprintf(buf[pos..], "Contact: <sip:server@127.0.0.1:5060>\r\n")!!.len;
    pos += io::bprintf(buf[pos..], "Content-Length: 0\r\n")!!.len;
    pos += io::bprintf(buf[pos..], "\r\n")!!.len;
    return pos;
}

fn void write_all(TcpSocket *client, String data)
{
    usz pos = 0;
    while (pos < data.len) {
        if (try sz sent = client.write(data[pos..])) {
            if (sent == 0) break;
            pos += (usz)sent;
        } else {
            break;
        }
    }
}

fn void handle_sip_request(TcpSocket *client, char[] buffer, usz len)
{
    String data = (String)buffer[:len];

    usz line_end = 0;
    while (line_end < data.len && data[line_end] != '\r') line_end++;
    if (line_end == 0) return;

    String request_line = data[0..line_end];

    usz space = 0;
    while (space < request_line.len && request_line[space] != ' ') space++;
    if (space == 0) return;
    String method = request_line[0..space];

    String via = extract_header(data, "Via:");
    String from_v = extract_header(data, "From:");
    String to_v = extract_header(data, "To:");
    String call_id = extract_header(data, "Call-ID:");
    String cseq = extract_header(data, "CSeq:");

    io::printfn("Received SIP %s request", method);

    char[1024] resp_buf;

    usz r1 = build_sip_response(resp_buf[..], "100 Trying", via, from_v, to_v, call_id, cseq);
    write_all(client, (String)resp_buf[:r1]);

    if (method == "INVITE") {
        usz r2 = build_sip_response(resp_buf[..], "180 Ringing", via, from_v, to_v, call_id, cseq);
        write_all(client, (String)resp_buf[:r2]);

        usz r3 = build_sip_response(resp_buf[..], "200 OK", via, from_v, to_v, call_id, cseq);
        write_all(client, (String)resp_buf[:r3]);
    }
}

fn void read_input(TcpSocket *client)
{
  defer (void) client.close();

  char[BUFFSIZE] buffer;

  while (try sz read = client.read(&buffer)) {
    handle_sip_request(client, buffer[..], (usz)read);
    if (read < BUFFSIZE) break;
  }
}

fn void handle_client(void *args) {
    ClientTask *task = (ClientTask*) args;
    TcpSocket *client = &task.client;

    read_input(client);

    free(args);
}

fn void? start_server(String host, int port, int limit = 50)
{
    bool server_active = true;

    TcpServerSocket? server = tcp::listen(
        host,
        port,
        (int) SocketOption.REUSEADDR.ordinal,
        ip_protocol: IpProtocol.IPV4
    );

    if (catch error = server) {
        io::printn("Unable to start server");

        return;
    }

    defer (void) server.close();

    while (server_active) {
        TcpSocket? client = tcp::accept(&server);

        if (catch error = client) {
            io::printfn("error accepting client %s", error);

            continue;
        }

        ClientTask *task = mem::new(ClientTask);
        task.client = client;

        Thread worker_thread;

        if (catch error = worker_thread.create(
                fn int(void* arg) {
                    handle_client((ClientTask*)arg);
                    return 0;
                },
                task,
                (ThreadSettings){}
            )) {
                io::printfn("error spawning thread: %s", error);
                mem::free(task);
                (void) client.close();
            }
    }
}
