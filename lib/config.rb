require 'yaml'
require 'active_support/core_ext/hash'

class Config
  FILE_PATH = File.join(File.expand_path(__dir__), '../config.yml')

  attr_reader :data

  def self.read
    hash = YAML.load_file FILE_PATH
    Config.new(deep_to_indifferent(hash))
  end

  def initialize(data)
    @data = data
  end

  def set(key, value)
    *path, final_key = key.split('.')
    to_set = path.empty? ? @data : @data.dig(*path)
    return unless to_set

    to_set[final_key] = value
    File.write(FILE_PATH, hash.to_yaml)
  end

  def [](name)
    @data[name]
  end

  def []=(name, value)
    @data[name] = value
  end

  def to_s
    "#<Config:0x#{object_id.to_s(16)} #{data.inspect}>"
  end

  alias :inspect :to_s

  class << self
    private

    def deep_to_indifferent(h)
      if h.is_a? Hash
        h.with_indifferent_access.transform_values { |v| deep_to_indifferent(v) }
      else
        h
      end
    end
  end
end
