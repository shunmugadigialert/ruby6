*   Define `ActiveJob::Base#options_for_global_id` to comply with strict loading

    ```ruby
    class Article < ApplicationRecord
      self.strict_loading_by_default = true

      has_and_belongs_to_many :tags
    end

    class Tag < ApplicationRecord
      has_and_belongs_to_many :articles
    end

    class PublishJob < ApplicationJob
      def perform(article)
        article.tags.each { |tag| ... }
      end

      private

      def options_for_global_id(model_class)
        if model_class == Article
          { includes: [:tags] }
        else
          super
        end
      end
    end
    ```

    *Sean Doyle*

*   Preserve the serialized timezone when deserializing `ActiveSupport::TimeWithZone` arguments.

    *Joshua Young*

*   Remove deprecated `:exponentially_longer` value for the `:wait` in `retry_on`.

    *Rafael Mendonça França*

*   Remove deprecated support to set numeric values to `scheduled_at` attribute.

    *Rafael Mendonça França*

*   Deprecate `Rails.application.config.active_job.use_big_decimal_serialize`.

    *Rafael Mendonça França*

*   Remove deprecated primitive serializer for `BigDecimal` arguments.

    *Rafael Mendonça França*

Please check [7-1-stable](https://github.com/rails/rails/blob/7-1-stable/activejob/CHANGELOG.md) for previous changes.
