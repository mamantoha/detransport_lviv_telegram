require "json"
require "crest"

alias EwayStops = Hash(String, Array(EwayStopElement))
alias EwayStopElement = Int32 | String | EwayStop

class EwayStop
  include JSON::Serializable

  property trol : String?
  property bus : String?
  property marshrutka : String?
  property tram : String?
end

class Stop
  include JSON::Serializable

  property id : Int32
  property lat : Float64
  property lng : Float64
  property name : String

  def initialize(@id, @lat, @lng, @name)
  end
end

# curl 'https://www.eway.in.ua/mobile_ajax/ua/lviv/stops' -H 'X-Requested-With: XMLHttpRequest' -H 'Cookie: city[key]=lviv; mobile_version=1; lang=ua'
response = Crest.get(
  "https://www.eway.in.ua/mobile_ajax/ua/lviv/stops",
  params: {"lang" => "ua"},
  headers: {"X-Requested-With" => "XMLHttpRequest"},
  cookies: {"city" => {"key" => "lviv"}, "mobile_version" => 1}
)

eway_stops = EwayStops.from_json(response.body)

stops = [] of Stop

eway_stops.each do |stop_id, value|
  stop = Stop.new(
    id: stop_id.to_i,
    lat: value[0].to_s.insert(2, '.').to_f,
    lng: value[1].to_s.insert(2, '.').to_f,
    name: value[2].to_s,
  )

  stops << stop
end

stops.sort_by!(&.id)

File.write("./src/detransport_telegram/data/lviv_stops.json", stops.to_pretty_json, mode: "w")
