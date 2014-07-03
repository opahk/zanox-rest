require 'httparty'
require 'base64'
require 'hmac-sha1'
require 'digest/md5'

class API
  include HTTParty

  ENDPOINT = '/json/2011-03-01'
  BASE_URI = 'api.zanox.com'

  attr_accessor :debug_output

  def initialize(connect_id, secret_key, debug_output = false)
    @connect_id = connect_id
    @secret_key = secret_key
    @debug_output = debug_output
  end

  def request(method, options = {})
    begin
      verb = options[:verb] || 'GET'
      timestamp = formatted_timestamp
      nonce = generate_nonce
      signature = create_signature @secret_key,
          verb + method.downcase + timestamp + nonce

      options.merge! connectid: @connect_id, date: timestamp,
        signature: signature, nonce: nonce

      response = get ENDPOINT + method, query: options

      puts response.parsed_response if @debug_output
      ZanoxAPI::Response.new response.parsed_response
    rescue Exception => e
      if @debug_output
        puts 'error'
        puts e.message
      end
      ZanoxAPI::Response.new({ error: true })
    end
  end

  private

    def generate_nonce
      Digest::MD5.hexdigest((Time.new.usec + rand()).to_s)
    end

    def formatted_timestamp
      Time.new.gmtime.strftime('%a, %d %b %Y %H:%M:%S GMT').to_s
    end

    def create_signature(secret_key, string2sign)
      puts string2sign if @debug_output
      encode_signature HMAC::SHA1.new(@secret_key).update(string2sign).digest
    end

    def encode_signature(signature)
      Base64.encode64(signature)[0..-2]
    end

    def format_date(date)
      "%d-%0*d-%0*d" % [date.year, 2, date.month, 2, date.day]
    end
end
