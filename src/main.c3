module c3_sip_server;

import std::io;
import std::net;

fn int main(String[] args)
{
    String host = "localhost";

    int port = 5060;
    int concurrent_request_limit = 100;

    start_server(host, port, concurrent_request_limit)!!;

    return 0;
}

fn String hello()
{
    return ("Hello, C3 SIP Server!");
}
