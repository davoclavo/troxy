defmodule Troxy.Interfaces.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import Troxy.PlugHelper

  @opts Troxy.Interfaces.Plug.init([])

  test "should skip plug if plug_skip_troxy private is set" do
    conn = create_conn
    |> Plug.Conn.put_private(:plug_skip_troxy, true)
    |> init_and_call_plug(Troxy.Interfaces.Plug, [])

    assert conn.halted == false
    assert conn.status == nil
  end

  test "reads the upstream from the host header" do
    conn = call_plug(@opts)
    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json"]
  end

  test "configurable to normalize the response headers" do
    opts = Troxy.Interfaces.Plug.init([normalize_headers?: true])
    conn = call_plug(opts)
    refute get_resp_header(conn, "Content-Type") == ["application/json"]
    assert get_resp_header(conn, "content-type") == ["application/json"]
  end

  test "configurable to leave intact the response headers" do
    opts = Troxy.Interfaces.Plug.init([normalize_headers?: false])

    # TODO: A mocked response with Non-Normalized-Header is needed, or add an endpoint to httparrot to customize header responses
    conn = call_plug(opts)
    assert get_resp_header(conn, "Content-Type") == ["application/json"]
    refute get_resp_header(conn, "content-type") == ["application/json"]
  end

  test "configurable to synchronously the response downstream"
  test "configurable to chunk the response downstream"

  test "supports HTTPS" do
    conn = create_conn(:httparrot, :https, :get, "/get")
    |> Troxy.Interfaces.Plug.call(@opts)
    assert conn.status == 200
  end

  test "rejects requests without host header" do
    assert_raise Troxy.Interfaces.Plug.Error, "missing request host header", fn ->
      create_conn
      |> delete_req_header("host")
      |> Troxy.Interfaces.Plug.call(@opts)
    end
  end

  test "defaults to not following redirects" do
    conn = create_conn(:httparrot, :http, :get, "/redirect/3")
           |> init_and_call_plug(Troxy.Interfaces.Plug, [])

    assert conn.status == 301
    location_header = List.first(get_resp_header(conn, "location"))
    assert(location_header =~ ~r(/redirect/\d$))
  end

  # TODO: cache these redirects?
  test "supports async GET redirects" do
    conn = create_conn(:httparrot, :http, :get, "/redirect/3")
    |> init_and_call_plug(Troxy.Interfaces.Plug, [follow_redirects?: true])
    assert conn.status == 200
  end

  test "supports async POST redirects with body forwarding"
  test "handles timeouts, :econnrefused, or :nxdomain errors" do
    conn = create_conn(:httparrot, :http, :get, "/delay/10")
    |> Troxy.Interfaces.Plug.call(@opts)
    assert conn.status == 200
  end

  defp call_plug(opts) do
    create_conn
    |> Troxy.Interfaces.Plug.call(opts)
  end


# HTTParrot supported requests
# /ip Returns Origin IP.
# /user-agent Returns user-agent.
# /headers Returns header dict.
# /get Returns GET data.
# /post Returns POST data.
# /put Returns PUT data.
# /patch Returns PATCH data.
# /delete Returns DELETE data
# /gzip Returns gzip-encoded data.
# /status/:code Returns given HTTP Status code.
# /redirect/:n 302 Redirects n times.
# /redirect-to?url=foo 302 Redirects to the foo URL.
# /relative-redirect/:n 302 Relative redirects n times.
# /cookies Returns cookie data.
# /cookies/set?name=value Sets one or more simple cookies.
# /cookies/delete?name Deletes one or more simple cookies.
# /basic-auth/:user/:passwd Challenges HTTPBasic Auth.
# /hidden-basic-auth/:user/:passwd 404'd BasicAuth.
# /stream/:n Streams n-100 lines.
# /html Renders an HTML Page.
# /robots.txt Returns some robots.txt rules.
# /deny Denied by robots.txt file.
# /cache 200 unless If-Modified-Since was sent, then 304.
# /base64/:value Decodes value base64url-encoded string.
# /image Return an image based on Accept header.
# /websocket Echo message received through websocket.
end
