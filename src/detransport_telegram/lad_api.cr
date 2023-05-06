module DetransportTelegram
  class LadAPI
    def initialize
      url = "https://api.eway.in.ua/"
      login = Config.eway_user
      password = Config.eway_password

      @conn = Crest::Resource.new(
        url,
        params: {
          "login"    => login,
          "password" => password,
          "city"     => "lviv",
          "lang"     => "ua",
          "format"   => "json",
          "v"        => "1.2",
        }
      )
    end

    def show_routes(code : Int32)
      resp = @conn["/"].get(params: {"function" => "stops.GetStopInfo", "id" => code})

      Routes.from_json(resp.body)
    end

    class Routes
      include JSON::Serializable

      property id : Int32

      property lat : Float64

      property lng : Float64

      property title : String

      property routes : Array(Route)
    end

    class Route
      include JSON::Serializable

      property id : Int32

      property title : String

      @[JSON::Field(key: "directionTitle")]
      property direction_title : String

      @[JSON::Field(key: "transportName")]
      property transport_name : String

      @[JSON::Field(key: "transportKey")]
      property transport_key : String

      @[JSON::Field(key: "hasGPS")]
      property? has_gps : Bool

      property? handicapped : Bool

      property? wifi : Bool

      @[JSON::Field(key: "hasSchedules")]
      property? has_schedules : Bool

      @[JSON::Field(key: "timeLeft")]
      property time_left : String

      @[JSON::Field(key: "timeLeftFormatted")]
      property time_left_formatted : String

      @[JSON::Field(key: "timeSource")]
      property time_source : String

      def full_title
        "#{transport_icon} *#{title}* _(#{direction_title})_ — #{time_left_formatted}"
      end

      def transport_icon
        case transport_key
        when "bus"
          "🚍"
        when "trol"
          "🚎"
        when "marshrutka"
          "🚌"
        when "tram"
          "🚃"
        when "train"
          "🚆"
        else
          "🚌"
        end
      end
    end
  end
end
