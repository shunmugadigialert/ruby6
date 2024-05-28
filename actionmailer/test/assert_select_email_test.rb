# frozen_string_literal: true

require "abstract_unit"

class AssertSelectMailerTest < ActionMailer::TestCase
  class AssertSelectMailer < ActionMailer::Base
    def test(html)
      mail body: html, content_type: "text/html",
        subject: "Test e-mail", from: "test@test.host", to: "test <test@test.host>"
    end
  end

  tests AssertSelectMailer

  def test_assert_select_email
    assert_raise ActiveSupport::TestCase::Assertion do
      assert_select_email { }
    end

    AssertSelectMailer.test("<div><p>foo</p><p>bar</p></div>").deliver_now
    assert_select_email do
      assert_select "div:root" do
        assert_select "p:first-child", "foo"
        assert_select "p:last-child", "bar"
      end
    end
  end

  def test_assert_part_last_mail_delivery
    AssertSelectMailer.test("<div><p>foo</p><p>bar</p></div>").deliver_now

    assert_part :html do |part|
      assert_includes part.body.raw_source, "<div><p>foo</p><p>bar</p></div>"
    end
    assert_html_part do |root|
      assert_select root, "div" do
        assert_select "p:first-child", "foo"
        assert_select "p:last-child", "bar"
      end
    end
  end

  def test_assert_part_with_mail_argument
    mail = AssertSelectMailer.test("<div><p>foo</p><p>bar</p></div>")

    assert_part mail, :html do |part|
      assert_includes part.body.raw_source, "<div><p>foo</p><p>bar</p></div>"
    end
    assert_html_part mail do |root|
      assert_select root, "div" do
        assert_select "p:first-child", "foo"
        assert_select "p:last-child", "bar"
      end
    end
  end
end

class AssertMultipartSelectMailerTest < ActionMailer::TestCase
  class AssertMultipartSelectMailer < ActionMailer::Base
    def test(options)
      mail subject: "Test e-mail", from: "test@test.host", to: "test <test@test.host>" do |format|
        format.text { render plain: options[:text] }
        format.html { render plain: options[:html] }
      end
    end
  end

  tests AssertMultipartSelectMailer

  def test_assert_select_email
    AssertMultipartSelectMailer.test(html: "<div><p>foo</p><p>bar</p></div>", text: "foo bar").deliver_now
    assert_select_email do
      assert_select "div:root" do
        assert_select "p:first-child", "foo"
        assert_select "p:last-child", "bar"
      end
    end
  end

  def test_assert_part_last_mail_delivery
    AssertMultipartSelectMailer.test(html: "<div><p>foo</p><p>bar</p></div>", text: "foo bar").deliver_now

    assert_part :text do |part|
      assert_includes part.body.raw_source, "foo bar"
    end
    assert_text_part do |text|
      assert_includes text, "foo bar"
    end
    assert_part :html do |part|
      assert_includes part.body.raw_source, "<div><p>foo</p><p>bar</p></div>"
    end
    assert_html_part do |root|
      assert_select root, "div" do
        assert_select "p:first-child", "foo"
        assert_select "p:last-child", "bar"
      end
    end
  end

  def test_assert_part_with_mail_argument
    mail = AssertMultipartSelectMailer.test(html: "<div><p>foo</p><p>bar</p></div>", text: "foo bar")

    assert_part mail, :text do |part|
      assert_includes part.body.raw_source, "foo bar"
    end
    assert_text_part mail do |text|
      assert_includes text, "foo bar"
    end
    assert_part mail, :html do |part|
      assert_includes part.body.raw_source, "<div><p>foo</p><p>bar</p></div>"
    end
    assert_html_part mail do |root|
      assert_select root, "div" do
        assert_select "p:first-child", "foo"
        assert_select "p:last-child", "bar"
      end
    end
  end
end
