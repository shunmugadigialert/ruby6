# frozen_string_literal: true

module Arel # :nodoc: all
  module AliasPredication
    def as(other)
      other = other.to_s if other.is_a?(Symbol)

      Nodes::As.new self, Nodes::SqlLiteral.new(other)
    end
  end
end
