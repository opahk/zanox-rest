require 'rubygems'
require 'active_support'

module ZanoxAPI
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

        timestamp = ZanoxAPI::API.get_timestamp
        nonce     = ZanoxAPI::API.generate_nonce
        signature = ZanoxAPI::API.create_signature @@secret_key,
            verb + method.downcase + timestamp + nonce

        options.merge!(:date => timestamp,
                       :signature => signature,
                       :nonce => nonce)

        response = get @@endpoint + method, :query => options

        puts response.parsed_response if @@debug_output
        ZanoxAPI::Response.new(response.parsed_response)
      rescue Exception => e
        if @@debug_output
          puts "error"
          puts e.message
        end
        ZanoxAPI::Response.new({:error => true})
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

    def self.basic (from, to, options = {})
      options.merge!(:fromdate  => ZanoxAPI::API.format_date(from),
                         :todate    => ZanoxAPI::API.format_date(to))
      ZanoxAPI::API.request('/reports/basic', options)
    end

    def self.sales (date, options = {})
      ZanoxAPI::API.request('/reports/sales/date/' + ZanoxAPI::API.format_date(date), options)
    end

    def self.salesitem (saleid, options = {})
      ZanoxAPI::API.request('/reports/sales/sale/' + saleid, options)
    end

    def self.leads (date, options = {})
      ZanoxAPI::API.request('/reports/leads/date/' + ZanoxAPI::API.format_date(date), options)
    end

    def self.leadsitem (lead_id, options = {})
      ZanoxAPI::API.request('/reports/leads/lead/' + lead_id, options)
    end

    def self.gpp (from, to, options = {})
      sales = (from.to_date..to.to_date).map do |date|
        ZanoxAPI::Report.sales(date, options)
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
            ZanoxAPI::Response.new(value)
          elsif value.instance_of? Array
            result = value.map { |x| ZanoxAPI::Response.new(x) }
            class << result
              def method_missing method, *params, &block
                self
              end
            end
            result
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
