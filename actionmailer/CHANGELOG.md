*   Introduce `config.action_mailer.html_assertions`

    Adds support for testing with `Capybara::Minitest::Assertions` when set to `:capybara`.
    Defaults to `Rails::Dom::Testing::Assertions` with `:rails_dom_testing`.

    *Sean Doyle*

*   Extend `ActionMailer::TestCase` with `#assert_part` assertion

    Also introduce `#assert_text_part` and `#assert_html_part` convenience
    methods:

    ```ruby
    test "asserts text parts" do
      mail = MyMailer.welcome("Hello, world")

      assert_part mail, :text do |part|
        assert_includes part.body.raw_source, "Hello, world"
      end
      assert_text_part mail do |text|
        assert_includes text, "Hello, world"
      end
    end

    test "asserts html parts" do
      mail = MyMailer.welcome("Hello, world")

      assert_part mail, :html do |part|
        assert_includes part.body.raw_source, "Hello, world"
      end
      assert_html_part mail do |html|
        assert_select html, "p", "Hello, world"
      end
    end
    ```

    *Sean Doyle*

Please check [7-2-stable](https://github.com/rails/rails/blob/7-2-stable/actionmailer/CHANGELOG.md) for previous changes.
