class CachedClosed
  def initialize(type)
    @type = type
    @closed = if File.exist?(file_name)
      Set.new(File.readlines(file_name).map(&:chomp))
    else
      Set.new
    end
  end

  def add(entry)
    @closed << entry
  end

  def include?(entry)
    @closed.include?(entry)
  end

  def save
    File.write(file_name, @closed.to_a.join("\n"))
  end

  private

  def file_name
    @file_name ||= begin
      date = Time.now.strftime("%m_%d_%Y")
      "cache/cache_closed/#{@type}_already_closed_#{date}"
    end
  end
end