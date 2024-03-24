*   Migrate `ActiveRecord::AttributeAssignment` support for multiparameter attributes to Active Model

    ```ruby
    class Topic
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :last_read_on, :date
    end

    topic = Topic.new(last_read_on: {
      "last_read_on(1i)" => "2023",
      "last_read_on(2i)" => "10",
      "last_read_on(3i)" => "17"
    })
    topic.last_read_on == Date.new(2023, 10, 17) # => true
    ```

    *Sean Doyle*

*   Fix a bug where type casting of string to `Time` and `DateTime` doesn't
    calculate minus minute value in TZ offset correctly.

    *Akira Matsuda*

*   Port the `type_for_attribute` method to Active Model. Classes that include
    `ActiveModel::Attributes` will now provide this method. This method behaves
    the same for Active Model as it does for Active Record.

      ```ruby
      class MyModel
        include ActiveModel::Attributes

        attribute :my_attribute, :integer
      end

      MyModel.type_for_attribute(:my_attribute) # => #<ActiveModel::Type::Integer ...>
      ```

    *Jonathan Hefner*

Please check [7-1-stable](https://github.com/rails/rails/blob/7-1-stable/activemodel/CHANGELOG.md) for previous changes.
