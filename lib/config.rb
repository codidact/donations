require 'ostruct'
require 'yaml'
require 'json'
require 'active_support/core_ext/hash'

class Config
  FILE_PATH = File.join(File.expand_path(__dir__), '../config.yml')

  attr_reader :data

  def self.read
    hash = YAML.load_file FILE_PATH
    json = hash.to_json
    Config.new(JSON.parse(json, object_class: OpenStruct))
  end

  def initialize(data)
    @data = data
  end

  def set(key, value)
    *path, final_key = key.split('.')
    hash = deep_to_h(data).deep_stringify_keys
    to_set = path.empty? ? hash : hash.dig(*path)
    return unless to_set

    to_set[final_key] = value
    File.write(FILE_PATH, hash.to_yaml)
  end

  def method_missing(name, *_args, **_opts, &_block)
    @data[name]
  end

  def respond_to_missing?(name, *_args, **_opts, &_block)
    @data.include? name
  end

  private

  def deep_to_h(os)
    if os.is_a? OpenStruct
      os.to_h.transform_values { |v| deep_to_h(v) }
    else
      os
    end
  end
end
