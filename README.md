# detransport_lviv_telegram

Source code for <https://t.me/DetransportBot>

| ![image](https://github.com/mamantoha/detransport_lviv_telegram/blob/master/screenshots/screenshot1.png?raw=true) | ![image](https://github.com/mamantoha/detransport_lviv_telegram/blob/master/screenshots/screenshot2.png?raw=true) | ![image](https://github.com/mamantoha/detransport_lviv_telegram/blob/master/screenshots/screenshot3.png?raw=true) |
| --- | --- | --- |

## Installation

### Requirements

- Crystal
- PostgreSQL

Clone repository:

```console
git clone https://github.com/mamantoha/detransport_lviv_telegram.git
```

### Setup Telegram

Copy `.env.example` to `.env` and set variables

### Setup Database

Copy `config/database.yml.example` to `config/database.yml` and set PostgreSQL variables

```console
crystal sam.cr db:setup
crystal sam.cr db:migrate
```

### Run

```console
shards build --release --production
./bin/detransport_telegram
```

## Development

```
psql -c 'DROP DATABASE IF EXISTS detransport_lviv_development;' -U postgres
psql -c 'CREATE DATABASE detransport_lviv_development;' -U postgres
```

### DB Migration

```console
crystal src/db.cr generate migration add_field_to_table
```

```crystal
crystal ./src/db.cr migrate
```

### Update stops

To update `./src/detransport_telegram/data/lviv_stops.json` run:

```console
crystal ./utils/update_stops.cr
```

## Deployment

### Linux with systemd

Create `/etc/systemd/system/detransport_lviv_telegram.service`

```ini
[Unit]
Description=Detransport Lviv Telegram service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=user
WorkingDirectory=/path/to/detransport_lviv_telegram
ExecStart=/path/to/detransport_lviv_telegram/bin/detransport_telegram &>/dev/null &
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
```

```console
sudo systemctl enable detransport_lviv_telegram
```

```console
sudo systemctl start detransport_lviv_telegram
```

## Contributing

1. Fork it (<https://github.com/mamantoha/detransport_lviv_telegram/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer
