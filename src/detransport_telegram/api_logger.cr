module DetransportTelegram
  class APILogger < Crest::Logger
    def initialize(io : IO = STDOUT)
      super(io)
      filter(/([?&](?:login|password)=)[^&\s]+/, "\\1[FILTERED]")
    end

    def request(request : Crest::Request) : Nil
      info("| #{request.method} | #{request.url}")
    end

    def response(response : Crest::Response) : Nil
      info("| #{response.status_code} | #{response.url} | #{response_body(response)}")
    end

    private def response_body(response : Crest::Response) : String
      JSON.parse(response.body).to_pretty_json
    rescue JSON::ParseException
      response.body.inspect
    end
  end
end
