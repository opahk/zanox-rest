require 'rubygems'
require 'active_support'

module Zanox
  module API
    require 'httparty'
    require 'base64'
    require 'hmac-sha1'
    require 'digest/md5'

    include HTTParty

    @@connect_id   = ENV['ZANOX_ID']
    @@secret_key   = ENV['ZANOX_KEY']
    @@endpoint     = '/json/2011-03-01'
    @@debug_output = false

    base_uri 'api.zanox.com:443'
    default_params :connectid => @@connect_id,
                   :currency  => 'EUR'

    format :json

    def self.request (method, options = {})
      begin
        options.merge!(:connectid => @@connect_id)

        verb = options[:verb] || 'GET'

        timestamp = Zanox::API.get_timestamp
        nonce     = Zanox::API.generate_nonce
        signature = Zanox::API.create_signature @@secret_key,
            verb + method.downcase + timestamp + nonce

        options.merge!(:date => timestamp,
                       :signature => signature,
                       :nonce => nonce)

        response = get @@endpoint + method, :query => options

        puts response.parsed_response if @@debug_output
        Zanox::Response.new(response.parsed_response)
      rescue Exception => e
        if @@debug_output
          puts "error"
          puts e.message
        end
        Zanox::Response.new({:error => true})
      end
    end

    def self.generate_nonce
      Digest::MD5.hexdigest((Time.new.usec + rand()).to_s)
    end

    def self.get_timestamp
      Time.new.gmtime.strftime("%a, %d %b %Y %H:%M:%S GMT").to_s
    end

    def self.create_signature(secret_key, string2sign)
      puts string2sign if @@debug_output
      Base64.encode64(HMAC::SHA1.new(@@secret_key).update(string2sign).digest)[0..-2]
    end

    def self.format_date (date)
      "%d-%0*d-%0*d" % [date.year, 2, date.month, 2, date.day]
    end

    def self.debug_output= value
      @@debug_output = value
    end
  end

  module Report

    def self.basic (from, to)
      Zanox::API.request('/reports/basic',
                         :fromdate  => Zanox::API.format_date(from),
                         :todate    => Zanox::API.format_date(to))
    end

    def self.sales (date)
      Zanox::API.request('/reports/sales/date/' + Zanox::API.format_date(date))
    end

    def self.salesitem (saleid)
      Zanox::API.request('/reports/sales/sale/' + saleid)
    end

    def self.gpp (from, to, gpp = {})
      sales = (from.to_date..to.to_date).map do |date|
        Zanox::Report.sales(date)
      end

      salesitems = []
      sales.each do |salesday|
        if salesday[:items] > 0
          salesitems += salesday[:salesitems]
        end
      end

    end
  end

  class Response
    def initialize (hash)

      hash.each do |key,value|
        method_name = ActiveSupport::Inflector.underscore key.to_s.gsub(/@/,'').gsub(/\$/,'value')
        define_singleton_method(method_name) do
          if value.instance_of? Hash
            Zanox::Response.new(value)
          elsif value.instance_of? Array
            value.map { |x| Zanox::Response.new(x) }
          else
            value
          end
        end
      end

      define_singleton_method("to_hash") do
        hash
      end

      define_singleton_method("method_missing") do |method, *params|
        class << nil
          def method_missing method, *params, &block
            self
          end
        end
      end

    end
  end
end
