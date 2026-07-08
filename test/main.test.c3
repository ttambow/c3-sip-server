import c3_sip_server;
import std::core::test;

fn void test_greeting() @test
{
    String hello = c3_sip_server::hello();
    assert(hello == "Hello, C3 SIP Server!", "greeting message is correct");
}