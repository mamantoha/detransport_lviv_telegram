module DetransportTelegram
  @@logger : Logger?

  def self.logger
    @@logger ||= Logger.new(STDOUT).tap do |l|
      l.level = Logger::Severity.parse("DEBUG")
    end
  end
end
