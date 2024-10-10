*   Add support for enabling or disabling transactions per database.

    This allows you to enable or disable transactions for a specific database,
    overriding the default setting specified by `use_transactional_tests`. This
    can be useful for read-only connections.

    ```ruby
    ActiveRecord::TestFixture.use_transactions_tests = true
    ActiveRecord::TestFixture.set_database_transactions(:readonly, false)
    ```

    Using `true` enables transactions, while `false` disables them. Passing
    `nil` will reset the setting to the default value, inherited from the
    `use_transactional_tests` setting.

    *Matthew Cheetham*, *Morgan Mareve*

Please check [8-0-stable](https://github.com/rails/rails/blob/8-0-stable/activerecord/CHANGELOG.md) for previous changes.
