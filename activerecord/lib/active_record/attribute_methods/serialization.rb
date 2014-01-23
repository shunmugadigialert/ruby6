module ActiveRecord
  module AttributeMethods
    module Serialization
      extend ActiveSupport::Concern

      included do
        # Returns a hash of all the attributes that have been specified for
        # serialization as keys and their class restriction as values.
        class_attribute :serialized_attributes, instance_accessor: false
        self.serialized_attributes = {}

        # Contains the options for each serialized attribute. Currently
        # only contains the value of the dirty property
        # TODO it would be cleaner if this included the coder...
        class_attribute :serialized_attribute_options,
          instance_accessor: false
        self.serialized_attribute_options = {}
      end

      module ClassMethods
        ##
        # :method: serialized_attributes
        #
        # Returns a hash of all the attributes that have been specified for
        # serialization as keys and their class restriction as values.

        # If you have an attribute that needs to be saved to the database as an
        # object, and retrieved as the same object, then specify the name of that
        # attribute using this method and it will be handled automatically. The
        # serialization is done through YAML. If +class_name+ is specified, the
        # serialized object must be of that class on retrieval or
        # <tt>SerializationTypeMismatch</tt> will be raised.
        #
        # A notable side effect of serialized attributes is that the model will
        # be updated on every save, even if it is not dirty.
        #
        # ==== Parameters
        #
        # * +attr_name+ - The field name that should be serialized.
        # * +class_name+ - Optional, class name that the object type should be equal to.
        #
        # ==== Example
        #
        #   # Serialize a preferences attribute.
        #   class User < ActiveRecord::Base
        #     serialize :preferences
        #   end
        def serialize(attr_name, class_name = Object, options = {})
          include Behavior

          # The class_name parameter is optional. You can define a
          # serialized attribute like this
          # `serialize :some_attribute, dirty: :never
          class_name, options = Object, class_name if class_name.is_a?(Hash)

          coder = if [:load, :dump].all? { |x| class_name.respond_to?(x) }
                    class_name
                  else
                    Coders::YAMLColumn.new(class_name)
                  end

          # merge new serialized attribute and create new hash to ensure that each class in inheritance hierarchy
          # has its own hash of own serialized attributes
          self.serialized_attributes = serialized_attributes.merge(attr_name.to_s => coder)

          # TODO: clone doesn't work if for whatever reason primitives like
          # fixnum are stored in a serialized column
          # TODO: if we want we can easily allow people to provider their own
          # procs to compare serialized fields
          options = {dirty: :always}.merge(options)
          case options[:dirty]
          when :clone then options[:compare_with] = Proc.new(&:clone)
          when :hash then options[:compare_with] = Proc.new(&:hash)
          end
          self.serialized_attribute_options = serialized_attribute_options.
            merge(attr_name.to_s => options)
        end
      end

      class Type # :nodoc:
        def initialize(column)
          @column = column
        end

        def type_cast(value)
          if value.state == :serialized
            value.unserialized_value @column.type_cast value.value
          else
            value.unserialized_value
          end
        end

        def type
          @column.type
        end

        def accessor
          ActiveRecord::Store::IndifferentHashAccessor
        end
      end

      class Attribute < Struct.new(:coder, :value, :state) # :nodoc:
        def unserialized_value(v = value)
          state == :serialized ? unserialize(v) : value
        end

        def serialized_value
          state == :unserialized ? serialize : value
        end

        def unserialize(v)
          self.state = :unserialized
          self.value = coder.load(v)
        end

        def serialize
          self.state = :serialized
          self.value = coder.dump(value)
        end
      end

      # This is only added to the model when serialize is called, which
      # ensures we do not make things slower when serialization is not used.
      module Behavior # :nodoc:
        extend ActiveSupport::Concern

        module ClassMethods # :nodoc:
          def initialize_attributes(attributes, options = {})
            serialized = (options.delete(:serialized) { true }) ? :serialized : :unserialized
            super(attributes, options)

            serialized_attributes.each do |key, coder|
              if attributes.key?(key)
                attributes[key] = Attribute.new(coder, attributes[key], serialized)
              end
            end
            attributes
          end

          # Returns an array of serialized attributes that are always
          # considered dirty, even if they didn't change
          def always_dirty_serialized_keys
            serialized_attributes.keys.select do |k|
              serialized_attribute_options[k][:dirty] == :always
            end
          end
        end

        def init_serialized_comparable
          @serialized_comparable = {}
          self.class.serialized_attribute_options.each do |attr, options|
            if @attributes.key?(attr) && options[:compare_with].present?
              @serialized_comparable[attr] = options[:compare_with].
                call(@attributes[attr].unserialized_value)
            end
          end
        end

        def attribute_changed?(attr)
          super || changed_serialized?(attr)
        end

        def changed?
          super || changed_serialized_keys.present?
        end

        # TODO this breaks when a a serialized attribute is set that was not
        # part of the original select statement. (`m = MyModel.select("some_col").first; m.some_serialized_col = {a:1}`)
        # I assume some other stuff breaks in that case, as well
        def changed_serialized?(attr)
          options = self.class.serialized_attribute_options[attr]
          return false if options.nil?
          comp = options[:compare_with]
          comp.nil? ? false : @serialized_comparable[attr] !=
            comp.call(@attributes[attr].unserialized_value)
        end

        def changed_serialized_keys
          @serialized_comparable.keys.select { |k| changed_serialized?(k) }
        end

        def should_record_timestamps?
          super || (self.record_timestamps && (attributes.keys &
            self.class.always_dirty_serialized_keys).present?)
        end

        def keys_for_partial_write
          super | changed_serialized_keys |
            (attributes.keys & self.class.always_dirty_serialized_keys)
        end

        def init_internals
          super.tap { init_serialized_comparable }
        end

        def changes_applied
          super.tap { init_serialized_comparable }
        end

        def reset_changes
          super.tap { init_serialized_comparable }
        end

        def type_cast_attribute_for_write(column, value)
          if column && coder = self.class.serialized_attributes[column.name]
            Attribute.new(coder, value, :unserialized)
          else
            super
          end
        end

        def _field_changed?(attr, old, value)
          if self.class.serialized_attributes.include?(attr)
            old != value
          else
            super
          end
        end

        def read_attribute_before_type_cast(attr_name)
          if self.class.serialized_attributes.include?(attr_name)
            super.unserialized_value
          else
            super
          end
        end

        def attributes_before_type_cast
          super.dup.tap do |attributes|
            self.class.serialized_attributes.each_key do |key|
              if attributes.key?(key)
                attributes[key] = attributes[key].unserialized_value
              end
            end
          end
        end

        def typecasted_attribute_value(name)
          if self.class.serialized_attributes.include?(name)
            @attributes[name].serialized_value
          else
            super
          end
        end
      end
    end
  end
end
