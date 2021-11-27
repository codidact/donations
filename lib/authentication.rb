require 'active_support/message_encryptor'
require 'active_support/key_generator'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/blank'
require_relative 'config'

class Authenticator
  COOKIE_NAME = :_session

  def initialize(cookies)
    @cookies = cookies
    @config  = Config.read

    unless @config.crypt.salt.present?
      salt = SecureRandom.random_bytes(ActiveSupport::MessageEncryptor.key_len)
      encoded = salt.chars.map { |c| c.ord.to_s(16) }.join
      @config.set('crypt.salt', encoded)
    end

    encoded = @config.crypt.salt
    salt = encoded.chars.each_slice(2).map { |pair| pair.join.to_i(16).chr }.join
    key = ActiveSupport::KeyGenerator.new(@config.crypt.master_key)
                                     .generate_key(salt, ActiveSupport::MessageEncryptor.key_len)
    @encryptor = ActiveSupport::MessageEncryptor.new(key)
  end

  def authenticated?
    begin
      with_session do |cookie|
        cookie[:user].present? && cookie[:user][:staff]
      end
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      false
    end
  end

  def current_user
    begin
      with_session do |cookie|
        cookie[:user]
      end
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end
  end

  def authenticate!(data)
    @cookies[COOKIE_NAME] = @encryptor.encrypt_and_sign(data.to_json)
  end

  def deauthenticate!
    @cookies.delete COOKIE_NAME
  end

  private

  def with_session
    if @cookies.include? COOKIE_NAME
      yield JSON.parse(@encryptor.decrypt_and_verify(@cookies[COOKIE_NAME])).with_indifferent_access
    end
  end
end
