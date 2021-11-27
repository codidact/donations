require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash'
require 'net/http'
require 'sinatra'
require 'sinatra/cookies'
require 'sinatra/reloader'
require_relative 'authentication'
require_relative 'config'

class DonationsList < Sinatra::Base
  FILE_PATH = File.join(File.expand_path(__dir__), '../donations.yml')

  helpers Sinatra::Cookies

  configure :development do
    register Sinatra::Reloader
  end

  set :public_folder, File.join(__dir__, 'static')

  def auth
    @auth ||= Authenticator.new(cookies)
  end

  def config
    @config ||= Config.read
  end

  def donations
    @donations ||= YAML.load_file(FILE_PATH)
  end

  def authenticated
    if auth.authenticated?
      yield
    else
      erb :login, locals: { config: config }
    end
  end

  get '/donations/application.css' do
    scss :application, style: :compressed
  end

  get '/donations/admin' do
    authenticated do
      data = YAML.load_file(FILE_PATH)
      erb :admin, locals: { current_user: auth.current_user, donations: data }
    end
  end

  post '/donations/admin' do
    authenticated do
      data = YAML.load_file(FILE_PATH) || []
      payload = JSON.parse(request.body.read)
      item = {
        'id' => (data&.map { |r| r['id'] }&.max || 0) + 1,
        'name' => payload['name'],
        'message' => payload['message'],
        'link' => payload['link']
      }

      data << item
      File.write(FILE_PATH, data.to_yaml)

      response.headers['Content-Type'] = 'application/json'
      item.to_json
    end
  end

  get '/donations/admin/:id' do
    authenticated do
      data = YAML.load_file(FILE_PATH)
      response.headers['Content-Type'] = 'application/json'
      data.select { |row| row['id'].to_s == params['id'] }[0].to_json
    end
  end

  post '/donations/admin/:id/edit' do
    authenticated do
      data = YAML.load_file(FILE_PATH)
      item = data.select { |row| row['id'].to_s == params['id'] }[0]
      idx  = data.index item

      payload = JSON.parse(request.body.read)

      item['name'] = payload['name']
      item['message'] = payload['message']
      item['link'] = payload['link']

      data[idx] = item
      File.write(FILE_PATH, data.to_yaml)

      response.headers['Content-Type'] = 'application/json'
      { status: 'success' }.to_json
    end
  end

  post '/donations/admin/:id/delete' do
    authenticated do
      data = YAML.load_file(FILE_PATH)
      item = data.select { |row| row['id'].to_s == params['id'] }[0]

      data.delete item
      File.write(FILE_PATH, data.to_yaml)

      response.headers['Content-Type'] = 'application/json'
      { status: 'success' }.to_json
    end
  end

  get '/donations/login' do
    if params['code'].present?
      auth_params = { app_id: config.oauth.app_id, secret: config.oauth.secret, code: params['code'] }.stringify_keys
      resp = Net::HTTP.post_form(URI('https://meta.codidact.com/oauth/token'), auth_params)
      if resp.code == '200'
        data = JSON.parse(resp.body)
        auth.authenticate! data
        redirect '/donations/admin'
      else
        status resp.code.to_i
        resp.body
      end
    else
      status 400
      'No code parameter present'
    end
  end

  post '/donations/logout' do
    auth.deauthenticate!
    redirect '/donations'
  end

  get '/donations' do
    erb :donations, locals: { donations: donations }
  end

  run!
end
