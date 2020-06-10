require "dotenv"
Dotenv.load

{% if compare_versions(Crystal::VERSION, "0.35.0-0") >= 0 %}
  alias CallStack = Exception::CallStack
{% end %}

require "sam"
require "./config/initializers/database"
require "./db/migrations/*"

load_dependencies "jennifer"

Sam.help
