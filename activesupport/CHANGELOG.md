*   Add `ActiveSupport::Testing::NotificationAssertions` module to help with testing `ActiveSupport::Notifications`.

    *Nicholas La Roux*, *Yishu See*, *Sean Doyle*

*   `ActiveSupport::JSON.encode` supports CIDR notation.

    Previously:

    ```ruby
    ActiveSupport::JSON.encode(IPAddr.new("172.16.0.0/24")) # => "\"172.16.0.0\""
    ```

    After this change:

    ```ruby
    ActiveSupport::JSON.encode(IPAddr.new("172.16.0.0/24")) # => "\"172.16.0.0/24\""
    ```

    *Taketo Takashima*

Please check [8-0-stable](https://github.com/rails/rails/blob/8-0-stable/activesupport/CHANGELOG.md) for previous changes.
