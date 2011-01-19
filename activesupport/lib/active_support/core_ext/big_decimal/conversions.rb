require 'bigdecimal'
require 'active_support/core_ext/yaml'

class BigDecimal
  unless defined?(Psych)
    YAML_TAG = 'tag:yaml.org,2002:float'
    YAML_MAPPING = { 'Infinity' => '.Inf', '-Infinity' => '-.Inf', 'NaN' => '.NaN' }

    # This emits the number without any scientific notation.
    # This is better than self.to_f.to_s since it doesn't lose precision.
    #
    # Note that reconstituting YAML floats to native floats may lose precision.
    def to_yaml(opts = {})
      YAML::Emitter.new.reset(opts).emit(nil) do |out|
        string = to_s
        out.scalar(YAML_TAG, YAML_MAPPING[string] || string, :plain)
      end
    end
  end

  def to_d
    self
  end

  DEFAULT_STRING_FORMAT = 'F'
  def to_formatted_s(format = DEFAULT_STRING_FORMAT)
    _original_to_s(format)
  end
  alias_method :_original_to_s, :to_s
  alias_method :to_s, :to_formatted_s
end
