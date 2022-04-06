require "json"
require "crest"

alias Stops = Hash(String, Array(StopElement))
alias StopElement = Int32 | String | Stop

class Stop
  include JSON::Serializable

  property trol : String?
  property bus : String?
  property marshrutka : String?
  property tram : String?
end

# curl 'https://www.eway.in.ua/mobile_ajax/ua/lviv/stops' -H 'X-Requested-With: XMLHttpRequest' -H 'Cookie: city[key]=lviv; mobile_version=1; lang=ua'
response = Crest.get(
  "https://www.eway.in.ua/mobile_ajax/ua/lviv/stops",
  params: {"lang" => "ua"},
  headers: {"X-Requested-With" => "XMLHttpRequest"},
  cookies: {"city" => {"key" => "lviv"}, "mobile_version" => 1}
)

json = JSON.parse(response.body)
stops = Stops.from_json(response.body)

stops_arry = [] of Hash(String, String | Float64 | Int32)

stops.each do |stop_id, value|
  stops_arry << {
    "id"   => stop_id.to_i,
    "lat"  => value[0].to_s.insert(2, '.').to_f,
    "lng"  => value[1].to_s.insert(2, '.').to_f,
    "name" => value[2].to_s,
  }
end

stops_arry.sort_by! { |hsh| hsh["id"].to_i }

File.write("./src/detransport_telegram/data/lviv_stops.json", stops_arry.to_pretty_json, mode: "w")
