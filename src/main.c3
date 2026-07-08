module c3_sip_server;
import std::io;

fn String hello()
{
    return ("Hello, C3 SIP Server!");
}

fn int main(String[] args)
{
    io::printn(hello());
    return 0;
}
