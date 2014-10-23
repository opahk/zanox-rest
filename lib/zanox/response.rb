module ZanoxAPI
  class Response
    def initialize(hash)
      @hash = hash

      hash.each do |key, value|
        method_name = method_from_key key
        define_singleton_method(method_name) do
          if value.instance_of? Hash
            self.class.new(value)
          elsif value.instance_of? Array
            value.map { |v| self.class.new(v) }
          else
            value
          end
        end
      end
    end

    def to_hash
      @hash
    end

    private

      def method_from_key(key)
        ActiveSupport::Inflector.underscore normalize(key)
      end

      def normalize(key)
        key.to_s.gsub(/@/,'').gsub(/\$/,'value')
      end
  end
end
