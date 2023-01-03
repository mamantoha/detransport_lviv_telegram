module DetransportTelegram
  class Stops
    getter stops : StopsIterator

    def initialize(@stops : StopsIterator)
    end

    def get_by_id(stop_id : Int32) : Stop?
      stops.find { |stop| stop.id == stop_id }
    end

    def nearest_to(latitude : Float64, longitude : Float64, count = 5) : Array(Stop)
      stops
        .sort_by { |stop| Haversine.distance(stop.latitude, stop.longitude, latitude, longitude) }
        .first(count)
    end

    def similar_to(name : String, count = 9) : Array(Stop)
      stops
        .map { |stop| {stop, FuzzyMatch::Full.new(name, stop.name.sub("вул. ", ""))} }
        .select(&.[1].matches?)
        .sort_by!(&.[1].score)
        .reverse!
        .map(&.[0])
        .first(count)
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
