module Gitlab
  module Ci
    class Config
      module Node
        class Entry
          attr_reader :value, :nodes, :parent

          def initialize(value, root = nil, parent = nil)
            @value = value
            @root = root
            @parent = parent
            @nodes, @errors = [], []

            keys.each_key do |key|
              instance_variable_set("@#{key}", Null.new(nil, root, self))
            end

            unless leaf? || value.is_a?(Hash)
              @errors << 'should be a configuration entry with hash value'
            end
          end

          def process!
            return if leaf? || !valid?

            keys.each do |key, entry_class|
              next unless @value.has_key?(key)

              entry = entry_class.new(@value[key], @root, self)
              instance_variable_set("@#{key}", entry)
              @nodes.append(entry)
            end

            nodes.each(&:process!)
            nodes.each(&:validate!)
          end

          def errors
            @errors + nodes.map(&:errors).flatten
          end

          def valid?
            errors.none?
          end

          def leaf?
            keys.none?
          end

          def keys
            self.class.nodes || {}
          end

          def validate!
            raise NotImplementedError
          end

          def description
            raise NotImplementedError
          end

          class << self
            attr_reader :nodes

            private

            def add_node(symbol, entry_class)
              (@nodes ||= {}).merge!(symbol.to_sym => entry_class)
            end
          end
        end
      end
    end
  end
end
