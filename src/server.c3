module c3_sip_server;

import std::io;
import std::collections;
import std::net;
import std::thread;

const int BUFFSIZE = 4096;
const int THREAD_COUNT = 100;
const int QUEUE_CAPACITY = 1000;

struct ClientTask {
    TcpSocket client;
}

fn void broadcast(TcpSocket *socket, List{String} *messages) {
  foreach (msg : messages) {
    int pos = 0;

    while (try sz sent = socket.write(msg[pos:msg.len])) {
      if (sent == 0) break;

      pos += (int) sent;

      if (pos >= msg.len) break;
    }
  }
}

fn void handle_client(void *args) {
    ClientTask *task = (ClientTask*) args;
    TcpSocket *client = &task.client;

    read_input(client);

    free(args);
}

fn void process_input(List{String} *input) {
    foreach (item : input) {
      io::printfn("%s", item);
    }
}

fn void read_input(TcpSocket *client) {
  defer (void) client.close();

  char[BUFFSIZE] buffer;
  List{String} data;

  data.init(mem);
  defer data.free();

  while (try sz read = client.read(&buffer)) {
    data.push((String)buffer[:read]);

    if (read < BUFFSIZE) break;
  }

  process_input(&data);
  broadcast(client, &data);
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
