class IO::MultiWriter < IO
  def flush
    @writers.each(&.flush)
  end
end
