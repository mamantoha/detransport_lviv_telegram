module DetransportTelegram
  class Stops
    getter stops : StopsIterator

    def initialize(@stops : StopsIterator)
    end

    def get_by_id(stop_id : Int32)
      stops.find { |stop| stop.id == stop_id }
    end

    def nearest_to(latitude : Float64, longitude : Float64, count = 5)
      sorted_stops = stops.sort_by do |stop|
        Haversine.distance(stop.latitude, stop.longitude, latitude, longitude)
      end

      sorted_stops.first(count)
    end

    def similar_to(name : String, count = 9)
      similar_stops = stops.sort_by do |stop|
        if name.size >= 4 && stop.name.downcase.includes?(name.downcase)
          1
        else
          JaroWinkler.new.distance(name.downcase, stop.name.downcase)
        end
      end

      similar_stops.reverse.first(count)
    end
  end

  alias StopsIterator = Array(Stop)

  class Stop
    include JSON::Serializable

    property id : Int32

    @[JSON::Field(key: "lat")]
    property latitude : Float64

    @[JSON::Field(key: "lng")]
    property longitude : Float64

    property name : String
    property direction : String?

    def full_name
      [name, direction].join(" ").rstrip
    end
  end
end
