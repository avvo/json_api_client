require 'forwardable'
require 'active_support/inflector'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/class/attribute'

module JsonApiClient
  class Resource
    class_attribute :site, :primary_key, :link_style

    self.primary_key = :id
    self.link_style = :id # or :url

    class << self
      # first 'scope' should build a new scope object
      extend Forwardable
      def_delegators :new_scope, :where, :order, :includes, :all

      # base URL for this resource
      def resource
        File.join(site, table_name)
      end

      def new_scope
        Scope.new(self)
      end

      def table_name
        resource_name.pluralize
      end

      def resource_name
        name.demodulize.underscore
      end

      def parser
        Parser
      end

      def parse(data)
        parser.parse(self, data)
      end

      def find(conditions)
        parse(connection.execute(Query::Find.new(self, conditions)))
      end

      def create(conditions = {})
        Array(parse(connection.execute(Query::Create.new(self, conditions)))).first
      end

      def connection
        @connection ||= begin
          super
        rescue
          build_connection
        end
      end

      private

      def build_connection
        Connection.new(site)
      end
    end

    attr_reader :links, :attributes
    def initialize(params = {})
      @links = params.delete(:links) || {}
      self.attributes = params
    end

    def attributes=(attrs = {})
      @attributes ||= {}.with_indifferent_access
      @attributes.merge!(attrs)
    end

    def save
      query = persisted? ? 
        Query::Update.new(self.class, self) :
        Query::Create.new(self.class, attributes)
      run_request(query)
    end

    def destroy
      run_request(Query::Destroy.new(self.class, self))
    end

    def update_attributes(attrs = {})
      self.attributes = attrs
      save
    end

    protected

    def run_request(query)
      parse(connection.execute(query))
    end

    def parse(data)
      self.class.parse(data)
    end

    def method_missing(method, *args, &block)
      if has_attribute?(method)
        attributes[method]
      else
        super
      end
    end

    def has_attribute?(attr_name)
      attributes.has_key?(attr_name)
    end

  end
end