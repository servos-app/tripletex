require_relative "test_helper"
require "socket"

class Tripletex::TransportTest < Minitest::Test
  def test_answers_with_the_status_body_and_downcased_headers_tripletex_sent
    server = TCPServer.new("127.0.0.1", 0)
    answer = Thread.new { answer_once(server) }
    request = Net::HTTP::Get.new(URI("http://127.0.0.1:#{server.addr[1]}/v2/customer"))

    response = Tripletex::Transport.perform(request, timeout: 5, open_timeout: 5)

    assert_equal 200, response.status
    assert_equal({"value" => {"id" => 1}}, response.data)
    assert_equal "req-1", response.request_id
  ensure
    answer&.kill
    server&.close
  end

  private

  def answer_once(server)
    client = server.accept
    client.gets("\r\n\r\n")
    body = {value: {id: 1}}.to_json
    client.write "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nX-TLX-Request-Id: req-1\r\n" \
      "Content-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}"
    client.close
  end
end
