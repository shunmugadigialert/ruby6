# frozen_string_literal: true

module ActiveRecord
  module Type
    class Serialized < DelegateClass(ActiveModel::Type::Value) # :nodoc:
      undef to_yaml if method_defined?(:to_yaml)

      include ActiveModel::Type::Helpers::Mutable

      attr_reader :subtype, :coder

      def initialize(subtype, coder)
        @subtype = subtype
        @coder = coder
        super(subtype)
      end

      def deserialize(value)
        coder.load(super)
      end

      def serialize(value)
        return if null_equivalent?(value)
        super coder.dump(value)
      end

      def inspect
        Kernel.instance_method(:inspect).bind(self).call
      end

      def changed_in_place?(raw_old_value, new_value)
        deserialize(raw_old_value) != new_value
      end

      def accessor
        ActiveRecord::Store::IndifferentHashAccessor
      end

      def assert_valid_value(value)
        if coder.respond_to?(:assert_valid_value)
          coder.assert_valid_value(value, action: "serialize")
        end
      end

      def force_equality?(value)
        coder.respond_to?(:object_class) && value.is_a?(coder.object_class)
      end

      private

        def null_equivalent?(value)
          value.nil? || value == coder.load(nil)
        end
    end
  end
end
