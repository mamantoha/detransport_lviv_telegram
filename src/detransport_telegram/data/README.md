## Lviv stops

```console
curl 'https://www.eway.in.ua/mobile_ajax/ua/lviv/stops' -H 'X-Requested-With: XMLHttpRequest' -H 'Cookie: city[key]=lviv; mobile_version=1; lang=ua' > stops.json
```

Download response as JSON.

Convert it with:

```ruby
require "json"

str = File.read("./src/detransport_telegram/data/stops.json")

json = JSON.parse(str)

stops = []

json.each do |stop_id, value|
  stops << {
    id: stop_id.to_i,
    lat: value[0].to_s.insert(2, '.').to_f,
    lng: value[1].to_s.insert(2, '.').to_f,
    name: value[2],
  }
end

file = File.open("./src/detransport_telegram/data/new_stops.json", "w")
file.write(stops.to_json)
```
