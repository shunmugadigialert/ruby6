require "abstract_unit"
require "controller/fake_models"

class FormWithTest < ActionView::TestCase
  include RenderERBUtils
end

class FormWithActsLikeFormTagTest < FormWithTest
  tests ActionView::Helpers::FormTagHelper

  setup do
    @controller = BasicController.new
  end

  def hidden_fields(options = {})
    method = options[:method]
    skip_enforcing_utf8 = options.fetch(:skip_enforcing_utf8, false)

    "".tap do |txt|
      unless skip_enforcing_utf8
        txt << %{<input name="utf8" type="hidden" value="&#x2713;" />}
      end

      if method && !%w(get post).include?(method.to_s)
        txt << %{<input name="_method" type="hidden" value="#{method}" />}
      end
    end
  end

  def form_text(action = "http://www.example.com", local: false, **options)
    enctype, html_class, id, method = options.values_at(:enctype, :html_class, :id, :method)

    method = method.to_s == "get" ? "get" : "post"

    txt =  %{<form accept-charset="UTF-8" action="#{action}"}
    txt << %{ enctype="multipart/form-data"} if enctype
    txt << %{ data-remote="true"} unless local
    txt << %{ class="#{html_class}"} if html_class
    txt << %{ id="#{id}"} if id
    txt << %{ method="#{method}">}
  end

  def whole_form(action = "http://www.example.com", options = {})
    out = form_text(action, options) + hidden_fields(options)

    if block_given?
      out << yield << "</form>"
    end

    out
  end

  def url_for(options)
    if options.is_a?(Hash)
      "http://www.example.com"
    else
      super
    end
  end

  def test_form_with_multipart
    actual = form_with(multipart: true)

    expected = whole_form("http://www.example.com", enctype: true)
    assert_dom_equal expected, actual
  end

  def test_form_with_with_method_patch
    actual = form_with(method: :patch)

    expected = whole_form("http://www.example.com", method: :patch)
    assert_dom_equal expected, actual
  end

  def test_form_with_with_method_put
    actual = form_with(method: :put)

    expected = whole_form("http://www.example.com", method: :put)
    assert_dom_equal expected, actual
  end

  def test_form_with_with_method_delete
    actual = form_with(method: :delete)

    expected = whole_form("http://www.example.com", method: :delete)
    assert_dom_equal expected, actual
  end

  def test_form_with_with_local_true
    actual = form_with(local: true)

    expected = whole_form("http://www.example.com", local: true)
    assert_dom_equal expected, actual
  end

  def test_form_with_skip_enforcing_utf8_true
    actual = form_with(skip_enforcing_utf8: true)
    expected = whole_form("http://www.example.com", skip_enforcing_utf8: true)
    assert_dom_equal expected, actual
    assert actual.html_safe?
  end

  def test_form_with_with_block_in_erb
    output_buffer = render_erb("<%= form_with(url: 'http://www.example.com') do %>Hello world!<% end %>")

    expected = whole_form { "Hello world!" }
    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_block_and_method_in_erb
    output_buffer = render_erb("<%= form_with(url: 'http://www.example.com', method: :put) do %>Hello world!<% end %>")

    expected = whole_form("http://www.example.com", method: "put") do
      "Hello world!"
    end

    assert_dom_equal expected, output_buffer
  end
end

class FormWithActsLikeFormForTest < FormWithTest
  def form_with(*)
    @output_buffer = super
  end

  teardown do
    I18n.backend.reload!
  end

  setup do
    # Create "label" locale for testing I18n label helpers
    I18n.backend.store_translations "label",
      activemodel: {
        attributes: {
          post: {
            cost: "Total cost"
          },
          "post/language": {
            spanish: "Espanol"
          }
        }
      },
      helpers: {
        label: {
          post: {
            body: "Write entire text here",
            color: {
              red: "Rojo"
            },
            comments: {
              body: "Write body here"
            }
          },
          tag: {
            value: "Tag"
          },
          post_delegate: {
            title: "Delegate model_name title"
          }
        }
      }

    # Create "submit" locale for testing I18n submit helpers
    I18n.backend.store_translations "submit",
      helpers: {
        submit: {
          create: "Create %{model}",
          update: "Confirm %{model} changes",
          submit: "Save changes",
          another_post: {
            update: "Update your %{model}"
          }
        }
      }

    I18n.backend.store_translations "placeholder",
      activemodel: {
        attributes: {
          post: {
            cost: "Total cost"
          },
          "post/cost": {
            uk: "Pounds"
          }
        }
      },
      helpers: {
        placeholder: {
          post: {
            title: "What is this about?",
            written_on: {
              spanish: "Escrito en"
            },
            comments: {
              body: "Write body here"
            }
          },
          post_delegate: {
            title: "Delegate model_name title"
          },
          tag: {
            value: "Tag"
          }
        }
      }

    @post = Post.new
    @comment = Comment.new
    def @post.errors()
      Class.new {
        def [](field); field == "author_name" ? ["can't be empty"] : [] end
        def empty?() false end
        def count() 1 end
        def full_messages() ["Author name can't be empty"] end
      }.new
    end
    def @post.to_key; [123]; end
    def @post.id; 0; end
    def @post.id_before_type_cast; "omg"; end
    def @post.id_came_from_user?; true; end
    def @post.to_param; "123"; end

    @post.persisted   = true
    @post.title       = "Hello World"
    @post.author_name = ""
    @post.body        = "Back to the hill and over it again!"
    @post.secret      = 1
    @post.written_on  = Date.new(2004, 6, 15)

    @post.comments = []
    @post.comments << @comment

    @post.tags = []
    @post.tags << Tag.new

    @post_delegator = PostDelegator.new

    @post_delegator.title = "Hello World"

    @car = Car.new("#000FFF")
  end

  Routes = ActionDispatch::Routing::RouteSet.new
  Routes.draw do
    resources :posts do
      resources :comments
    end

    namespace :admin do
      resources :posts do
        resources :comments
      end
    end

    get "/foo", to: "controller#action"
    root to: "main#index"
  end

  def _routes
    Routes
  end

  include Routes.url_helpers

  def url_for(object)
    @url_for_options = object

    if object.is_a?(Hash) && object[:use_route].blank? && object[:controller].blank?
      object.merge!(controller: "main", action: "index")
    end

    super
  end

  def test_form_with_requires_arguments
    error = assert_raises(ArgumentError) do
      form_for(nil, html: { id: "create-post" }) do
      end
    end
    assert_equal "First argument in form cannot contain nil or be empty", error.message

    error = assert_raises(ArgumentError) do
      form_for([nil, nil], html: { id: "create-post" }) do
      end
    end
    assert_equal "First argument in form cannot contain nil or be empty", error.message
  end

  def test_form_with
    form_with(model: @post, id: "create-post") do |f|
      concat f.label(:title) { "The Title" }
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
      concat f.submit("Create post")
      concat f.button("Create post")
      concat f.button {
        concat content_tag(:span, "Create post")
      }
    end

    expected = whole_form("/posts/123", "create-post", method: "patch") do
      "<label for='post_title'>The Title</label>" +
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />" +
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[secret]' type='hidden' value='0' />" +
      "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />" +
      "<input name='commit' data-disable-with='Create post' type='submit' value='Create post' />" +
      "<button name='button' type='submit'>Create post</button>" +
      "<button name='button' type='submit'><span>Create post</span></button>"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_collection_radio_buttons
    post = Post.new
    def post.active; false; end
    form_with(model: post) do |f|
      concat f.collection_radio_buttons(:active, [true, false], :to_s, :to_s)
    end

    expected = whole_form("/posts") do
      "<input type='hidden' name='post[active]' value='' />" +
      "<input id='post_active_true' name='post[active]' type='radio' value='true' />" +
      "<label for='post_active_true'>true</label>" +
      "<input checked='checked' id='post_active_false' name='post[active]' type='radio' value='false' />" +
      "<label for='post_active_false'>false</label>"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_collection_radio_buttons_with_custom_builder_block
    post = Post.new
    def post.active; false; end

    form_with(model: post) do |f|
      rendered_radio_buttons = f.collection_radio_buttons(:active, [true, false], :to_s, :to_s) do |b|
        b.label { b.radio_button + b.text }
      end
      concat rendered_radio_buttons
    end

    expected = whole_form("/posts") do
      "<input type='hidden' name='post[active]' value='' />" +
      "<label for='post_active_true'>" +
      "<input id='post_active_true' name='post[active]' type='radio' value='true' />" +
      "true</label>" +
      "<label for='post_active_false'>" +
      "<input checked='checked' id='post_active_false' name='post[active]' type='radio' value='false' />" +
      "false</label>"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_collection_radio_buttons_with_custom_builder_block_does_not_leak_the_template
    post = Post.new
    def post.active; false; end
    def post.id; 1; end

    form_with(model: post) do |f|
      rendered_radio_buttons = f.collection_radio_buttons(:active, [true, false], :to_s, :to_s) do |b|
        b.label { b.radio_button + b.text }
      end
      concat rendered_radio_buttons
      concat f.hidden_field :id
    end

    expected = whole_form("/posts") do
      "<input type='hidden' name='post[active]' value='' />" +
      "<label for='post_active_true'>" +
      "<input id='post_active_true' name='post[active]' type='radio' value='true' />" +
      "true</label>" +
      "<label for='post_active_false'>" +
      "<input checked='checked' id='post_active_false' name='post[active]' type='radio' value='false' />" +
      "false</label>" +
      "<input id='post_id' name='post[id]' type='hidden' value='1' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_index_and_with_collection_radio_buttons
    post = Post.new
    def post.active; false; end

    form_with(model: post, index: "1") do |f|
      concat f.collection_radio_buttons(:active, [true, false], :to_s, :to_s)
    end

    expected = whole_form("/posts") do
      "<input type='hidden' name='post[1][active]' value='' />" +
      "<input id='post_1_active_true' name='post[1][active]' type='radio' value='true' />" +
      "<label for='post_1_active_true'>true</label>" +
      "<input checked='checked' id='post_1_active_false' name='post[1][active]' type='radio' value='false' />" +
      "<label for='post_1_active_false'>false</label>"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_collection_check_boxes
    post = Post.new
    def post.tag_ids; [1, 3]; end
    collection = (1..3).map { |i| [i, "Tag #{i}"] }
    form_with(model: post) do |f|
      concat f.collection_check_boxes(:tag_ids, collection, :first, :last)
    end

    expected = whole_form("/posts") do
      "<input name='post[tag_ids][]' type='hidden' value='' />" +
      "<input checked='checked' id='post_tag_ids_1' name='post[tag_ids][]' type='checkbox' value='1' />" +
      "<label for='post_tag_ids_1'>Tag 1</label>" +
      "<input id='post_tag_ids_2' name='post[tag_ids][]' type='checkbox' value='2' />" +
      "<label for='post_tag_ids_2'>Tag 2</label>" +
      "<input checked='checked' id='post_tag_ids_3' name='post[tag_ids][]' type='checkbox' value='3' />" +
      "<label for='post_tag_ids_3'>Tag 3</label>"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_collection_check_boxes_with_custom_builder_block
    post = Post.new
    def post.tag_ids; [1, 3]; end
    collection = (1..3).map { |i| [i, "Tag #{i}"] }
    form_with(model: post) do |f|
      rendered_check_boxes = f.collection_check_boxes(:tag_ids, collection, :first, :last) do |b|
        b.label { b.check_box + b.text }
      end
      concat rendered_check_boxes
    end

    expected = whole_form("/posts") do
      "<input name='post[tag_ids][]' type='hidden' value='' />" +
      "<label for='post_tag_ids_1'>" +
      "<input checked='checked' id='post_tag_ids_1' name='post[tag_ids][]' type='checkbox' value='1' />" +
      "Tag 1</label>" +
      "<label for='post_tag_ids_2'>" +
      "<input id='post_tag_ids_2' name='post[tag_ids][]' type='checkbox' value='2' />" +
      "Tag 2</label>" +
      "<label for='post_tag_ids_3'>" +
      "<input checked='checked' id='post_tag_ids_3' name='post[tag_ids][]' type='checkbox' value='3' />" +
      "Tag 3</label>"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_collection_check_boxes_with_custom_builder_block_does_not_leak_the_template
    post = Post.new
    def post.tag_ids; [1, 3]; end
    def post.id; 1; end
    collection = (1..3).map { |i| [i, "Tag #{i}"] }

    form_with(model: post) do |f|
      rendered_check_boxes = f.collection_check_boxes(:tag_ids, collection, :first, :last) do |b|
        b.label { b.check_box + b.text }
      end
      concat rendered_check_boxes
      concat f.hidden_field :id
    end

    expected = whole_form("/posts") do
      "<input name='post[tag_ids][]' type='hidden' value='' />" +
      "<label for='post_tag_ids_1'>" +
      "<input checked='checked' id='post_tag_ids_1' name='post[tag_ids][]' type='checkbox' value='1' />" +
      "Tag 1</label>" +
      "<label for='post_tag_ids_2'>" +
      "<input id='post_tag_ids_2' name='post[tag_ids][]' type='checkbox' value='2' />" +
      "Tag 2</label>" +
      "<label for='post_tag_ids_3'>" +
      "<input checked='checked' id='post_tag_ids_3' name='post[tag_ids][]' type='checkbox' value='3' />" +
      "Tag 3</label>" +
      "<input id='post_id' name='post[id]' type='hidden' value='1' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_index_and_with_collection_check_boxes
    post = Post.new
    def post.tag_ids; [1]; end
    collection = [[1, "Tag 1"]]

    form_with(model: post, index: "1") do |f|
      concat f.collection_check_boxes(:tag_ids, collection, :first, :last)
    end

    expected = whole_form("/posts") do
      "<input name='post[1][tag_ids][]' type='hidden' value='' />" +
      "<input checked='checked' id='post_1_tag_ids_1' name='post[1][tag_ids][]' type='checkbox' value='1' />" +
      "<label for='post_1_tag_ids_1'>Tag 1</label>"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_file_field_generate_multipart
    form_with(model: @post, id: "create-post") do |f|
      concat f.file_field(:file)
    end

    expected = whole_form("/posts/123", "create-post", method: "patch", multipart: true) do
      "<input name='post[file]' type='file' id='post_file' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_fields_with_file_field_generate_multipart
    form_with(model: @post) do |f|
      concat f.fields(:comment, model: @post) { |c|
        concat c.file_field(:file)
      }
    end

    expected = whole_form("/posts/123", method: "patch", multipart: true) do
      "<input name='post[comment][file]' type='file' id='post_comment_file' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_format
    form_with(model: @post, format: :json, id: "edit_post_123", class: "edit_post") do |f|
      concat f.label(:title)
    end

    expected = whole_form("/posts/123.json", "edit_post_123", "edit_post", method: "patch") do
      "<label for='post_title'>Title</label>"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_format_and_url
    form_with(model: @post, format: :json, url: "/") do |f|
      concat f.label(:title)
    end

    expected = whole_form("/", method: "patch") do
      "<label for='post_title'>Title</label>"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_model_using_relative_model_naming
    blog_post = Blog::Post.new("And his name will be forty and four.", 44)

    form_with(model: blog_post) do |f|
      concat f.text_field :title
      concat f.submit("Edit post")
    end

    expected = whole_form("/posts/44", method: "patch") do
      "<input name='post[title]' type='text' id='post_title' value='And his name will be forty and four.' />" +
      "<input name='commit' data-disable-with='Edit post' type='submit' value='Edit post' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_symbol_scope
    form_with(model: @post, scope: "other_name", id: "create-post") do |f|
      concat f.label(:title, class: "post_title")
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
      concat f.submit("Create post")
    end

    expected = whole_form("/posts/123", "create-post", method: "patch") do
      "<label for='other_name_title' class='post_title'>Title</label>" +
      "<input name='other_name[title]' id='other_name_title' value='Hello World' type='text' />" +
      "<textarea name='other_name[body]' id='other_name_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='other_name[secret]' value='0' type='hidden' />" +
      "<input name='other_name[secret]' checked='checked' id='other_name_secret' value='1' type='checkbox' />" +
      "<input name='commit' value='Create post' data-disable-with='Create post' type='submit' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_tags_do_not_call_private_properties_on_form_object
    obj = Class.new do
      private def private_property
        raise "This method should not be called."
      end
    end.new

    form_with(model: obj, scope: "other_name", url: "/", id: "edit-other-name") do |f|
      assert_raise(NoMethodError) { f.hidden_field(:private_property) }
    end
  end

  def test_form_with_with_method_as_part_of_html_options
    form_with(model: @post, url: "/", id: "create-post", html: { method: :delete }) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected = whole_form("/", "create-post", method: "delete") do
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />" +
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[secret]' type='hidden' value='0' />" +
      "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_method
    form_with(model: @post, url: "/", method: :delete, id: "create-post") do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected = whole_form("/", "create-post", method: "delete") do
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />" +
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[secret]' type='hidden' value='0' />" +
      "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_search_field
    # Test case for bug which would emit an "object" attribute
    # when used with form_for using a search_field form helper
    form_with(model: Post.new, url: "/search", id: "search-post", method: :get) do |f|
      concat f.search_field(:title)
    end

    expected = whole_form("/search", "search-post", method: "get") do
      "<input name='post[title]' type='search' id='post_title' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_enables_remote_by_default
    form_with(model: @post, url: "/", id: "create-post", method: :patch) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected = whole_form("/", "create-post", method: "patch") do
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />" +
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[secret]' type='hidden' value='0' />" +
      "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_skip_enforcing_utf8_true
    form_with(scope: :post, skip_enforcing_utf8: true) do |f|
      concat f.text_field(:title)
    end

    expected = whole_form("/", skip_enforcing_utf8: true) do
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_skip_enforcing_utf8_false
    form_with(scope: :post, skip_enforcing_utf8: false) do |f|
      concat f.text_field(:title)
    end

    expected = whole_form("/", skip_enforcing_utf8: false) do
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_without_object
    form_with(scope: :post, id: "create-post") do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected = whole_form("/", "create-post") do
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />" +
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[secret]' type='hidden' value='0' />" +
      "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_index
    form_with(model: @post, scope: "post[]") do |f|
      concat f.label(:title)
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<label for='post_123_title'>Title</label>" +
      "<input name='post[123][title]' type='text' id='post_123_title' value='Hello World' />" +
      "<textarea name='post[123][body]' id='post_123_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[123][secret]' type='hidden' value='0' />" +
      "<input name='post[123][secret]' checked='checked' type='checkbox' id='post_123_secret' value='1' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_nil_index_option_override
    form_with(model: @post, scope: "post[]", index: nil) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<input name='post[][title]' type='text' id='post__title' value='Hello World' />" +
      "<textarea name='post[][body]' id='post__body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[][secret]' type='hidden' value='0' />" +
      "<input name='post[][secret]' checked='checked' type='checkbox' id='post__secret' value='1' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_label_error_wrapping
    form_with(model: @post) do |f|
      concat f.label(:author_name, class: "label")
      concat f.text_field(:author_name)
      concat f.submit("Create post")
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<div class='field_with_errors'><label for='post_author_name' class='label'>Author name</label></div>" +
      "<div class='field_with_errors'><input name='post[author_name]' type='text' id='post_author_name' value='' /></div>" +
      "<input name='commit' data-disable-with='Create post' type='submit' value='Create post' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_label_error_wrapping_without_conventional_instance_variable
    post = remove_instance_variable :@post

    form_with(model: post) do |f|
      concat f.label(:author_name, class: "label")
      concat f.text_field(:author_name)
      concat f.submit("Create post")
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<div class='field_with_errors'><label for='post_author_name' class='label'>Author name</label></div>" +
      "<div class='field_with_errors'><input name='post[author_name]' type='text' id='post_author_name' value='' /></div>" +
      "<input name='commit' data-disable-with='Create post' type='submit' value='Create post' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_label_error_wrapping_block_and_non_block_versions
    form_with(model: @post) do |f|
      concat f.label(:author_name, "Name", class: "label")
      concat f.label(:author_name, class: "label") { "Name" }
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<div class='field_with_errors'><label for='post_author_name' class='label'>Name</label></div>" +
      "<div class='field_with_errors'><label for='post_author_name' class='label'>Name</label></div>"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_namespace
    skip "Do namespaces still make sense?"
    form_for(@post, namespace: "namespace") do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected = whole_form("/posts/123", "namespace_edit_post_123", "edit_post", method: "patch") do
      "<input name='post[title]' type='text' id='namespace_post_title' value='Hello World' />" +
      "<textarea name='post[body]' id='namespace_post_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[secret]' type='hidden' value='0' />" +
      "<input name='post[secret]' checked='checked' type='checkbox' id='namespace_post_secret' value='1' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_submit_with_object_as_new_record_and_locale_strings
    with_locale :submit do
      @post.persisted = false
      @post.stub(:to_key, nil) do
        form_with(model: @post) do |f|
          concat f.submit
        end

        expected = whole_form("/posts") do
          "<input name='commit' data-disable-with='Create Post' type='submit' value='Create Post' />"
        end

        assert_dom_equal expected, output_buffer
      end
    end
  end

  def test_submit_with_object_as_existing_record_and_locale_strings
    with_locale :submit do
      form_with(model: @post) do |f|
        concat f.submit
      end

      expected = whole_form("/posts/123", method: "patch") do
        "<input name='commit' data-disable-with='Confirm Post changes' type='submit' value='Confirm Post changes' />"
      end

      assert_dom_equal expected, output_buffer
    end
  end

  def test_submit_without_object_and_locale_strings
    with_locale :submit do
      form_with(scope: :post) do |f|
        concat f.submit class: "extra"
      end

      expected = whole_form do
        "<input name='commit' class='extra' data-disable-with='Save changes' type='submit' value='Save changes' />"
      end

      assert_dom_equal expected, output_buffer
    end
  end

  def test_submit_with_object_and_nested_lookup
    with_locale :submit do
      form_with(model: @post, scope: :another_post) do |f|
        concat f.submit
      end

      expected = whole_form("/posts/123", method: "patch") do
        "<input name='commit' data-disable-with='Update your Post' type='submit' value='Update your Post' />"
      end

      assert_dom_equal expected, output_buffer
    end
  end

  def test_nested_fields
    @comment.body = "Hello World"
    form_with(model: @post) do |f|
      concat f.fields(model: @comment) { |c|
        concat c.text_field(:body)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<input name='post[comment][body]' type='text' id='post_comment_body' value='Hello World' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_deep_nested_fields
    @comment.save
    form_with(scope: :posts) do |f|
      f.fields("post[]", model: @post) do |f2|
        f2.text_field(:id)
        @post.comments.each do |comment|
          concat f2.fields("comment[]", model: comment) { |c|
            concat c.text_field(:name)
          }
        end
      end
    end

    expected = whole_form do
      "<input name='posts[post][0][comment][1][name]' type='text' id='posts_post_0_comment_1_name' value='comment #1' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_nested_collections
    form_with(model: @post, scope: "post[]") do |f|
      concat f.text_field(:title)
      concat f.fields("comment[]", model: @comment) { |c|
        concat c.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<input name='post[123][title]' type='text' id='post_123_title' value='Hello World' />" +
      "<input name='post[123][comment][][name]' type='text' id='post_123_comment__name' value='new comment' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_index_and_parent_fields
    form_with(model: @post, index: 1) do |c|
      concat c.text_field(:title)
      concat c.fields("comment", model: @comment, index: 1) { |r|
        concat r.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<input name='post[1][title]' type='text' id='post_1_title' value='Hello World' />" +
      "<input name='post[1][comment][1][name]' type='text' id='post_1_comment_1_name' value='new comment' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_index_and_nested_fields
    output_buffer = form_with(model: @post, index: 1) do |f|
      concat f.fields(:comment, model: @post) { |c|
        concat c.text_field(:title)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<input name='post[1][comment][title]' type='text' id='post_1_comment_title' value='Hello World' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_index_on_both
    form_with(model: @post, index: 1) do |f|
      concat f.fields(:comment, model: @post, index: 5) { |c|
        concat c.text_field(:title)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<input name='post[1][comment][5][title]' type='text' id='post_1_comment_5_title' value='Hello World' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_auto_index
    form_with(model: @post, scope: "post[]") do |f|
      concat f.fields(:comment, model: @post) { |c|
        concat c.text_field(:title)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<input name='post[123][comment][title]' type='text' id='post_123_comment_title' value='Hello World' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_index_radio_button
    form_with(model: @post) do |f|
      concat f.fields(:comment, model: @post, index: 5) { |c|
        concat c.radio_button(:title, "hello")
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<input name='post[comment][5][title]' type='radio' id='post_comment_5_title_hello' value='hello' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_auto_index_on_both
    form_with(model: @post, scope: "post[]") do |f|
      concat f.fields("comment[]", model: @post) { |c|
        concat c.text_field(:title)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<input name='post[123][comment][123][title]' type='text' id='post_123_comment_123_title' value='Hello World' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_index_and_auto_index
    output_buffer = form_with(model: @post, scope: "post[]") do |f|
      concat f.fields(:comment, model: @post, index: 5) { |c|
        concat c.text_field(:title)
      }
    end

    output_buffer << form_with(model: @post, index: 1) do |f|
      concat f.fields("comment[]", model: @post) { |c|
        concat c.text_field(:title)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<input name='post[123][comment][5][title]' type='text' id='post_123_comment_5_title' value='Hello World' />"
    end + whole_form("/posts/123", method: "patch") do
      "<input name='post[1][comment][123][title]' type='text' id='post_1_comment_123_title' value='Hello World' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_a_new_record_on_a_nested_attributes_one_to_one_association
    @post.author = Author.new

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      concat f.fields(:author) { |af|
        concat af.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
        '<input id="post_author_attributes_name" name="post[author_attributes][name]" type="text" value="new author" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_explicitly_passed_object_on_a_nested_attributes_one_to_one_association
    form_with(model: @post) do |f|
      f.fields(:author, model: Author.new(123)) do |af|
        assert_not_nil af.object
        assert_equal 123, af.object.id
      end
    end
  end

  def test_nested_fields_with_an_existing_record_on_a_nested_attributes_one_to_one_association
    @post.author = Author.new(321)

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      concat f.fields(:author) { |af|
        concat af.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_author_attributes_name" name="post[author_attributes][name]" type="text" value="author #321" />' +
      '<input id="post_author_attributes_id" name="post[author_attributes][id]" type="hidden" value="321" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_an_existing_record_on_a_nested_attributes_one_to_one_association_using_erb_and_inline_block
    @post.author = Author.new(321)

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      concat f.fields(:author) { |af|
        af.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_author_attributes_name" name="post[author_attributes][name]" type="text" value="author #321" />' +
      '<input id="post_author_attributes_id" name="post[author_attributes][id]" type="hidden" value="321" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_an_existing_record_on_a_nested_attributes_one_to_one_association_with_disabled_hidden_id
    @post.author = Author.new(321)

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      concat f.fields(:author, skip_id: true) { |af|
        af.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_author_attributes_name" name="post[author_attributes][name]" type="text" value="author #321" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_an_existing_record_on_a_nested_attributes_one_to_one_association_with_disabled_hidden_id_inherited
    @post.author = Author.new(321)

    form_with(model: @post, skip_id: true) do |f|
      concat f.text_field(:title)
      concat f.fields(:author) { |af|
        af.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_author_attributes_name" name="post[author_attributes][name]" type="text" value="author #321" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_an_existing_record_on_a_nested_attributes_one_to_one_association_with_disabled_hidden_id_override
    @post.author = Author.new(321)

    form_with(model: @post, skip_id: true) do |f|
      concat f.text_field(:title)
      concat f.fields(:author, skip_id: false) { |af|
        af.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_author_attributes_name" name="post[author_attributes][name]" type="text" value="author #321" />' +
      '<input id="post_author_attributes_id" name="post[author_attributes][id]" type="hidden" value="321" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_existing_records_on_a_nested_attributes_one_to_one_association_with_explicit_hidden_field_placement
    @post.author = Author.new(321)

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      concat f.fields(:author) { |af|
        concat af.hidden_field(:id)
        concat af.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_author_attributes_id" name="post[author_attributes][id]" type="hidden" value="321" />' +
      '<input id="post_author_attributes_name" name="post[author_attributes][name]" type="text" value="author #321" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_existing_records_on_a_nested_attributes_collection_association
    @post.comments = Array.new(2) { |id| Comment.new(id + 1) }

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      @post.comments.each do |comment|
        concat f.fields(:comments, model: comment) { |cf|
          concat cf.text_field(:name)
        }
      end
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #1" />' +
      '<input id="post_comments_attributes_0_id" name="post[comments_attributes][0][id]" type="hidden" value="1" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="comment #2" />' +
      '<input id="post_comments_attributes_1_id" name="post[comments_attributes][1][id]" type="hidden" value="2" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_existing_records_on_a_nested_attributes_collection_association_with_disabled_hidden_id
    @post.comments = Array.new(2) { |id| Comment.new(id + 1) }
    @post.author = Author.new(321)

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      concat f.fields(:author) { |af|
        concat af.text_field(:name)
      }
      @post.comments.each do |comment|
        concat f.fields(:comments, model: comment, skip_id: true) { |cf|
          concat cf.text_field(:name)
        }
      end
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_author_attributes_name" name="post[author_attributes][name]" type="text" value="author #321" />' +
      '<input id="post_author_attributes_id" name="post[author_attributes][id]" type="hidden" value="321" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #1" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="comment #2" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_existing_records_on_a_nested_attributes_collection_association_with_disabled_hidden_id_inherited
    @post.comments = Array.new(2) { |id| Comment.new(id + 1) }
    @post.author = Author.new(321)

    form_with(model: @post, skip_id: true) do |f|
      concat f.text_field(:title)
      concat f.fields(:author) { |af|
        concat af.text_field(:name)
      }
      @post.comments.each do |comment|
        concat f.fields(:comments, model: comment) { |cf|
          concat cf.text_field(:name)
        }
      end
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_author_attributes_name" name="post[author_attributes][name]" type="text" value="author #321" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #1" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="comment #2" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_existing_records_on_a_nested_attributes_collection_association_with_disabled_hidden_id_override
    @post.comments = Array.new(2) { |id| Comment.new(id + 1) }
    @post.author = Author.new(321)

    form_with(model: @post, skip_id: true) do |f|
      concat f.text_field(:title)
      concat f.fields(:author, skip_id: false) { |af|
        concat af.text_field(:name)
      }
      @post.comments.each do |comment|
        concat f.fields(:comments, model: comment) { |cf|
          concat cf.text_field(:name)
        }
      end
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_author_attributes_name" name="post[author_attributes][name]" type="text" value="author #321" />' +
      '<input id="post_author_attributes_id" name="post[author_attributes][id]" type="hidden" value="321" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #1" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="comment #2" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_existing_records_on_a_nested_attributes_collection_association_using_erb_and_inline_block
    @post.comments = Array.new(2) { |id| Comment.new(id + 1) }

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      @post.comments.each do |comment|
        concat f.fields(:comments, model: comment) { |cf|
          cf.text_field(:name)
        }
      end
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #1" />' +
      '<input id="post_comments_attributes_0_id" name="post[comments_attributes][0][id]" type="hidden" value="1" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="comment #2" />' +
      '<input id="post_comments_attributes_1_id" name="post[comments_attributes][1][id]" type="hidden" value="2" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_existing_records_on_a_nested_attributes_collection_association_with_explicit_hidden_field_placement
    @post.comments = Array.new(2) { |id| Comment.new(id + 1) }

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      @post.comments.each do |comment|
        concat f.fields(:comments, model: comment) { |cf|
          concat cf.hidden_field(:id)
          concat cf.text_field(:name)
        }
      end
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_comments_attributes_0_id" name="post[comments_attributes][0][id]" type="hidden" value="1" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #1" />' +
      '<input id="post_comments_attributes_1_id" name="post[comments_attributes][1][id]" type="hidden" value="2" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="comment #2" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_new_records_on_a_nested_attributes_collection_association
    @post.comments = [Comment.new, Comment.new]

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      @post.comments.each do |comment|
        concat f.fields(:comments, model: comment) { |cf|
          concat cf.text_field(:name)
        }
      end
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="new comment" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="new comment" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_existing_and_new_records_on_a_nested_attributes_collection_association
    @post.comments = [Comment.new(321), Comment.new]

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      @post.comments.each do |comment|
        concat f.fields(:comments, model: comment) { |cf|
          concat cf.text_field(:name)
        }
      end
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #321" />' +
      '<input id="post_comments_attributes_0_id" name="post[comments_attributes][0][id]" type="hidden" value="321" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="new comment" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_an_empty_supplied_attributes_collection
    form_with(model: @post) do |f|
      concat f.text_field(:title)
      f.fields(:comments, model: []) do |cf|
        concat cf.text_field(:name)
      end
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_existing_records_on_a_supplied_nested_attributes_collection
    @post.comments = Array.new(2) { |id| Comment.new(id + 1) }

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      concat f.fields(:comments, model: @post.comments) { |cf|
        concat cf.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #1" />' +
      '<input id="post_comments_attributes_0_id" name="post[comments_attributes][0][id]" type="hidden" value="1" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="comment #2" />' +
      '<input id="post_comments_attributes_1_id" name="post[comments_attributes][1][id]" type="hidden" value="2" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_arel_like
    @post.comments = ArelLike.new

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      concat f.fields(:comments, model: @post.comments) { |cf|
        concat cf.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #1" />' +
      '<input id="post_comments_attributes_0_id" name="post[comments_attributes][0][id]" type="hidden" value="1" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="comment #2" />' +
      '<input id="post_comments_attributes_1_id" name="post[comments_attributes][1][id]" type="hidden" value="2" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_label_translation_with_more_than_10_records
    @post.comments = Array.new(11) { |id| Comment.new(id + 1) }

    params = 11.times.map { ["post.comments.body", default: [:"comment.body", ""], scope: "helpers.label"] }
    assert_called_with(I18n, :t, params, returns: "Write body here") do
      form_with(model: @post) do |f|
        f.fields(:comments) do |cf|
          concat cf.label(:body)
        end
      end
    end
  end

  def test_nested_fields_with_existing_records_on_a_supplied_nested_attributes_collection_different_from_record_one
    comments = Array.new(2) { |id| Comment.new(id + 1) }
    @post.comments = []

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      concat f.fields(:comments, model: comments) { |cf|
        concat cf.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #1" />' +
      '<input id="post_comments_attributes_0_id" name="post[comments_attributes][0][id]" type="hidden" value="1" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="comment #2" />' +
      '<input id="post_comments_attributes_1_id" name="post[comments_attributes][1][id]" type="hidden" value="2" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_on_a_nested_attributes_collection_association_yields_only_builder
    @post.comments = [Comment.new(321), Comment.new]
    yielded_comments = []

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      concat f.fields(:comments) { |cf|
        concat cf.text_field(:name)
        yielded_comments << cf.object
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input name="post[title]" type="text" id="post_title" value="Hello World" />' +
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #321" />' +
      '<input id="post_comments_attributes_0_id" name="post[comments_attributes][0][id]" type="hidden" value="321" />' +
      '<input id="post_comments_attributes_1_name" name="post[comments_attributes][1][name]" type="text" value="new comment" />'
    end

    assert_dom_equal expected, output_buffer
    assert_equal yielded_comments, @post.comments
  end

  def test_nested_fields_with_child_index_option_override_on_a_nested_attributes_collection_association
    @post.comments = []

    form_with(model: @post) do |f|
      concat f.fields(:comments, model: Comment.new(321), child_index: "abc") { |cf|
        concat cf.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input id="post_comments_attributes_abc_name" name="post[comments_attributes][abc][name]" type="text" value="comment #321" />' +
      '<input id="post_comments_attributes_abc_id" name="post[comments_attributes][abc][id]" type="hidden" value="321" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_child_index_as_lambda_option_override_on_a_nested_attributes_collection_association
    @post.comments = []

    form_with(model: @post) do |f|
      concat f.fields(:comments, model: Comment.new(321), child_index: -> { "abc" }) { |cf|
        concat cf.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input id="post_comments_attributes_abc_name" name="post[comments_attributes][abc][name]" type="text" value="comment #321" />' +
      '<input id="post_comments_attributes_abc_id" name="post[comments_attributes][abc][id]" type="hidden" value="321" />'
    end

    assert_dom_equal expected, output_buffer
  end

  class FakeAssociationProxy
    def to_ary
      [1, 2, 3]
    end
  end

  def test_nested_fields_with_child_index_option_override_on_a_nested_attributes_collection_association_with_proxy
    @post.comments = FakeAssociationProxy.new

    form_with(model: @post) do |f|
      concat f.fields(:comments, model: Comment.new(321), child_index: "abc") { |cf|
        concat cf.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input id="post_comments_attributes_abc_name" name="post[comments_attributes][abc][name]" type="text" value="comment #321" />' +
      '<input id="post_comments_attributes_abc_id" name="post[comments_attributes][abc][id]" type="hidden" value="321" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_index_method_with_existing_records_on_a_nested_attributes_collection_association
    @post.comments = Array.new(2) { |id| Comment.new(id + 1) }

    form_with(model: @post) do |f|
      expected = 0
      @post.comments.each do |comment|
        f.fields(:comments, model: comment) { |cf|
          assert_equal cf.index, expected
          expected += 1
        }
      end
    end
  end

  def test_nested_fields_index_method_with_existing_and_new_records_on_a_nested_attributes_collection_association
    @post.comments = [Comment.new(321), Comment.new]

    form_with(model: @post) do |f|
      expected = 0
      @post.comments.each do |comment|
        f.fields(:comments, model: comment) { |cf|
          assert_equal cf.index, expected
          expected += 1
        }
      end
    end
  end

  def test_nested_fields_index_method_with_existing_records_on_a_supplied_nested_attributes_collection
    @post.comments = Array.new(2) { |id| Comment.new(id + 1) }

    form_with(model: @post) do |f|
      expected = 0
      f.fields(:comments, model: @post.comments) { |cf|
        assert_equal cf.index, expected
        expected += 1
      }
    end
  end

  def test_nested_fields_index_method_with_child_index_option_override_on_a_nested_attributes_collection_association
    @post.comments = []

    form_with(model: @post) do |f|
      f.fields(:comments, model: Comment.new(321), child_index: "abc") { |cf|
        assert_equal cf.index, "abc"
      }
    end
  end

  def test_nested_fields_uses_unique_indices_for_different_collection_associations
    @post.comments = [Comment.new(321)]
    @post.tags = [Tag.new(123), Tag.new(456)]
    @post.comments[0].relevances = []
    @post.tags[0].relevances = []
    @post.tags[1].relevances = []

    form_with(model: @post) do |f|
      concat f.fields(:comments, model: @post.comments[0]) { |cf|
        concat cf.text_field(:name)
        concat cf.fields(:relevances, model: CommentRelevance.new(314)) { |crf|
          concat crf.text_field(:value)
        }
      }
      concat f.fields(:tags, model: @post.tags[0]) { |tf|
        concat tf.text_field(:value)
        concat tf.fields(:relevances, model: TagRelevance.new(3141)) { |trf|
          concat trf.text_field(:value)
        }
      }
      concat f.fields("tags", model: @post.tags[1]) { |tf|
        concat tf.text_field(:value)
        concat tf.fields(:relevances, model: TagRelevance.new(31415)) { |trf|
          concat trf.text_field(:value)
        }
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input id="post_comments_attributes_0_name" name="post[comments_attributes][0][name]" type="text" value="comment #321" />' +
      '<input id="post_comments_attributes_0_relevances_attributes_0_value" name="post[comments_attributes][0][relevances_attributes][0][value]" type="text" value="commentrelevance #314" />' +
      '<input id="post_comments_attributes_0_relevances_attributes_0_id" name="post[comments_attributes][0][relevances_attributes][0][id]" type="hidden" value="314" />' +
      '<input id="post_comments_attributes_0_id" name="post[comments_attributes][0][id]" type="hidden" value="321" />' +
      '<input id="post_tags_attributes_0_value" name="post[tags_attributes][0][value]" type="text" value="tag #123" />' +
      '<input id="post_tags_attributes_0_relevances_attributes_0_value" name="post[tags_attributes][0][relevances_attributes][0][value]" type="text" value="tagrelevance #3141" />' +
      '<input id="post_tags_attributes_0_relevances_attributes_0_id" name="post[tags_attributes][0][relevances_attributes][0][id]" type="hidden" value="3141" />' +
      '<input id="post_tags_attributes_0_id" name="post[tags_attributes][0][id]" type="hidden" value="123" />' +
      '<input id="post_tags_attributes_1_value" name="post[tags_attributes][1][value]" type="text" value="tag #456" />' +
      '<input id="post_tags_attributes_1_relevances_attributes_0_value" name="post[tags_attributes][1][relevances_attributes][0][value]" type="text" value="tagrelevance #31415" />' +
      '<input id="post_tags_attributes_1_relevances_attributes_0_id" name="post[tags_attributes][1][relevances_attributes][0][id]" type="hidden" value="31415" />' +
      '<input id="post_tags_attributes_1_id" name="post[tags_attributes][1][id]" type="hidden" value="456" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_nested_fields_with_hash_like_model
    @author = HashBackedAuthor.new

    form_with(model: @post) do |f|
      concat f.fields(:author, model: @author) { |af|
        concat af.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      '<input id="post_author_attributes_name" name="post[author_attributes][name]" type="text" value="hash backed author" />'
    end

    assert_dom_equal expected, output_buffer
  end

  def test_fields
    output_buffer = fields(:post, model: @post) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected =
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />" +
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[secret]' type='hidden' value='0' />" +
      "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />"

    assert_dom_equal expected, output_buffer
  end

  def test_fields_with_index
    output_buffer = fields("post[]", model: @post) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected =
      "<input name='post[123][title]' type='text' id='post_123_title' value='Hello World' />" +
      "<textarea name='post[123][body]' id='post_123_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[123][secret]' type='hidden' value='0' />" +
      "<input name='post[123][secret]' checked='checked' type='checkbox' id='post_123_secret' value='1' />"

    assert_dom_equal expected, output_buffer
  end

  def test_fields_with_nil_index_option_override
    output_buffer = fields("post[]", model: @post, index: nil) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected =
      "<input name='post[][title]' type='text' id='post__title' value='Hello World' />" +
      "<textarea name='post[][body]' id='post__body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[][secret]' type='hidden' value='0' />" +
      "<input name='post[][secret]' checked='checked' type='checkbox' id='post__secret' value='1' />"

    assert_dom_equal expected, output_buffer
  end

  def test_fields_with_index_option_override
    output_buffer = fields("post[]", model: @post, index: "abc") do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected =
      "<input name='post[abc][title]' type='text' id='post_abc_title' value='Hello World' />" +
      "<textarea name='post[abc][body]' id='post_abc_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[abc][secret]' type='hidden' value='0' />" +
      "<input name='post[abc][secret]' checked='checked' type='checkbox' id='post_abc_secret' value='1' />"

    assert_dom_equal expected, output_buffer
  end

  def test_fields_without_object
    output_buffer = fields(:post) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected =
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />" +
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[secret]' type='hidden' value='0' />" +
      "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />"

    assert_dom_equal expected, output_buffer
  end

  def test_fields_with_only_object
    output_buffer = fields(model: @post) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected =
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />" +
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[secret]' type='hidden' value='0' />" +
      "<input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' />"

    assert_dom_equal expected, output_buffer
  end

  def test_fields_object_with_bracketed_name
    output_buffer = fields("author[post]", model: @post) do |f|
      concat f.label(:title)
      concat f.text_field(:title)
    end

    assert_dom_equal "<label for=\"author_post_title\">Title</label>" +
    "<input name='author[post][title]' type='text' id='author_post_title' value='Hello World' />",
      output_buffer
  end

  def test_fields_object_with_bracketed_name_and_index
    output_buffer = fields("author[post]", model: @post, index: 1) do |f|
      concat f.label(:title)
      concat f.text_field(:title)
    end

    assert_dom_equal "<label for=\"author_post_1_title\">Title</label>" +
      "<input name='author[post][1][title]' type='text' id='author_post_1_title' value='Hello World' />",
      output_buffer
  end

  def test_form_builder_does_not_have_form_with_method
    assert_not_includes ActionView::Helpers::FormBuilder.instance_methods, :form_with
  end

  def test_form_with_and_fields
    form_with(model: @post, scope: :post, id: "create-post") do |post_form|
      concat post_form.text_field(:title)
      concat post_form.text_area(:body)

      concat fields(:parent_post, model: @post) { |parent_fields|
        concat parent_fields.check_box(:secret)
      }
    end

    expected = whole_form("/posts/123", "create-post", method: "patch") do
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />" +
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='parent_post[secret]' type='hidden' value='0' />" +
      "<input name='parent_post[secret]' checked='checked' type='checkbox' id='parent_post_secret' value='1' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_and_fields_with_object
    form_with(model: @post, scope: :post, id: "create-post") do |post_form|
      concat post_form.text_field(:title)
      concat post_form.text_area(:body)

      concat post_form.fields(model: @comment) { |comment_fields|
        concat comment_fields.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", "create-post", method: "patch") do
      "<input name='post[title]' type='text' id='post_title' value='Hello World' />" +
      "<textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea>" +
      "<input name='post[comment][name]' type='text' id='post_comment_name' value='new comment' />"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_and_fields_with_non_nested_association_and_without_object
    form_with(model: @post) do |f|
      concat f.fields(:category) { |c|
        concat c.text_field(:name)
      }
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<input name='post[category][name]' type='text' id='post_category_name' />"
    end

    assert_dom_equal expected, output_buffer
  end

  class LabelledFormBuilder < ActionView::Helpers::FormBuilder
    (field_helpers - %w(hidden_field)).each do |selector|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{selector}(field, *args, &proc)
          ("<label for='\#{field}'>\#{field.to_s.humanize}:</label> " + super + "<br/>").html_safe
        end
      RUBY_EVAL
    end
  end

  def test_form_with_with_labelled_builder
    form_with(model: @post, builder: LabelledFormBuilder) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<label for='title'>Title:</label> <input name='post[title]' type='text' id='post_title' value='Hello World' /><br/>" +
      "<label for='body'>Body:</label> <textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea><br/>" +
      "<label for='secret'>Secret:</label> <input name='post[secret]' type='hidden' value='0' /><input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' /><br/>"
    end

    assert_dom_equal expected, output_buffer
  end

  def test_default_form_builder
    old_default_form_builder, ActionView::Base.default_form_builder =
      ActionView::Base.default_form_builder, LabelledFormBuilder

    form_with(model: @post) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<label for='title'>Title:</label> <input name='post[title]' type='text' id='post_title' value='Hello World' /><br/>" +
      "<label for='body'>Body:</label> <textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea><br/>" +
      "<label for='secret'>Secret:</label> <input name='post[secret]' type='hidden' value='0' /><input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' /><br/>"
    end

    assert_dom_equal expected, output_buffer
  ensure
    ActionView::Base.default_form_builder = old_default_form_builder
  end

  def test_lazy_loading_default_form_builder
    old_default_form_builder, ActionView::Base.default_form_builder =
      ActionView::Base.default_form_builder, "FormWithActsLikeFormForTest::LabelledFormBuilder"

    form_with(model: @post) do |f|
      concat f.text_field(:title)
    end

    expected = whole_form("/posts/123", method: "patch") do
      "<label for='title'>Title:</label> <input name='post[title]' type='text' id='post_title' value='Hello World' /><br/>"
    end

    assert_dom_equal expected, output_buffer
  ensure
    ActionView::Base.default_form_builder = old_default_form_builder
  end

  def test_form_builder_override
    self.default_form_builder = LabelledFormBuilder

    output_buffer = fields(:post, model: @post) do |f|
      concat f.text_field(:title)
    end

    expected = "<label for='title'>Title:</label> <input name='post[title]' type='text' id='post_title' value='Hello World' /><br/>"

    assert_dom_equal expected, output_buffer
  end

  def test_lazy_loading_form_builder_override
    self.default_form_builder = "FormWithActsLikeFormForTest::LabelledFormBuilder"

    output_buffer = fields(:post, model: @post) do |f|
      concat f.text_field(:title)
    end

    expected = "<label for='title'>Title:</label> <input name='post[title]' type='text' id='post_title' value='Hello World' /><br/>"

    assert_dom_equal expected, output_buffer
  end

  def test_fields_with_labelled_builder
    output_buffer = fields(:post, model: @post, builder: LabelledFormBuilder) do |f|
      concat f.text_field(:title)
      concat f.text_area(:body)
      concat f.check_box(:secret)
    end

    expected =
      "<label for='title'>Title:</label> <input name='post[title]' type='text' id='post_title' value='Hello World' /><br/>" +
      "<label for='body'>Body:</label> <textarea name='post[body]' id='post_body'>\nBack to the hill and over it again!</textarea><br/>" +
      "<label for='secret'>Secret:</label> <input name='post[secret]' type='hidden' value='0' /><input name='post[secret]' checked='checked' type='checkbox' id='post_secret' value='1' /><br/>"

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_labelled_builder_with_nested_fields_without_options_hash
    klass = nil

    form_with(model: @post, builder: LabelledFormBuilder) do |f|
      f.fields(:comments, model: Comment.new) do |nested_fields|
        klass = nested_fields.class
        ""
      end
    end

    assert_equal LabelledFormBuilder, klass
  end

  def test_form_with_with_labelled_builder_with_nested_fields_with_options_hash
    klass = nil

    form_with(model: @post, builder: LabelledFormBuilder) do |f|
      f.fields(:comments, model: Comment.new, index: "foo") do |nested_fields|
        klass = nested_fields.class
        ""
      end
    end

    assert_equal LabelledFormBuilder, klass
  end

  def test_form_with_with_labelled_builder_path
    path = nil

    form_with(model: @post, builder: LabelledFormBuilder) do |f|
      path = f.to_partial_path
      ""
    end

    assert_equal "labelled_form", path
  end

  class LabelledFormBuilderSubclass < LabelledFormBuilder; end

  def test_form_with_with_labelled_builder_with_nested_fields_with_custom_builder
    klass = nil

    form_with(model: @post, builder: LabelledFormBuilder) do |f|
      f.fields(:comments, model: Comment.new, builder: LabelledFormBuilderSubclass) do |nested_fields|
        klass = nested_fields.class
        ""
      end
    end

    assert_equal LabelledFormBuilderSubclass, klass
  end

  def test_form_with_with_html_options_adds_options_to_form_tag
    form_with(model: @post, html: { id: "some_form", class: "some_class", multipart: true }) do |f| end
    expected = whole_form("/posts/123", "some_form", "some_class", method: "patch", multipart: "multipart/form-data")

    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_string_url_option
    form_with(model: @post, url: "http://www.otherdomain.com") do |f| end

    assert_dom_equal whole_form("http://www.otherdomain.com", method: "patch"), output_buffer
  end

  def test_form_with_with_hash_url_option
    form_with(model: @post, url: { controller: "controller", action: "action" }) do |f| end

    assert_equal "controller", @url_for_options[:controller]
    assert_equal "action", @url_for_options[:action]
  end

  def test_form_with_with_record_url_option
    form_with(model: @post, url: @post) do |f| end

    expected = whole_form("/posts/123", method: "patch")
    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_existing_object
    form_with(model: @post) do |f| end

    expected = whole_form("/posts/123", method: "patch")
    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_new_object
    post = Post.new
    post.persisted = false
    def post.to_key; nil; end

    form_with(model: post) {}

    expected = whole_form("/posts")
    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_existing_object_in_list
    @comment.save
    form_with(model: [@post, @comment]) {}

    expected = whole_form(post_comment_path(@post, @comment), method: "patch")
    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_new_object_in_list
    form_with(model: [@post, @comment]) {}

    expected = whole_form(post_comments_path(@post))
    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_existing_object_and_namespace_in_list
    @comment.save
    form_with(model: [:admin, @post, @comment]) {}

    expected = whole_form(admin_post_comment_path(@post, @comment), method: "patch")
    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_new_object_and_namespace_in_list
    form_with(model: [:admin, @post, @comment]) {}

    expected = whole_form(admin_post_comments_path(@post))
    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_existing_object_and_custom_url
    form_with(model: @post, url: "/super_posts") do |f| end

    expected = whole_form("/super_posts", method: "patch")
    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_default_method_as_patch
    form_with(model: @post) {}
    expected = whole_form("/posts/123", method: "patch")
    assert_dom_equal expected, output_buffer
  end

  def test_form_with_with_data_attributes
    form_with(model: @post, data: { behavior: "stuff" }) {}
    assert_match %r|data-behavior="stuff"|, output_buffer
    assert_match %r|data-remote="true"|, output_buffer
  end

  def test_fields_returns_block_result
    output = fields(model: Post.new) { |f| "fields" }
    assert_equal "fields", output
  end

  def test_form_with_only_instantiates_builder_once
    initialization_count = 0
    builder_class = Class.new(ActionView::Helpers::FormBuilder) do
      define_method :initialize do |*args|
        super(*args)
        initialization_count += 1
      end
    end

    form_with(model: @post, builder: builder_class) {}
    assert_equal 1, initialization_count, "form builder instantiated more than once"
  end

  protected
    def hidden_fields(options = {})
      method = options[:method]

      if options.fetch(:skip_enforcing_utf8, false)
        txt = ""
      else
        txt = %{<input name="utf8" type="hidden" value="&#x2713;" />}
      end

      if method && !%w(get post).include?(method.to_s)
        txt << %{<input name="_method" type="hidden" value="#{method}" />}
      end

      txt
    end

    def form_text(action = "/", id = nil, html_class = nil, local = nil, multipart = nil, method = nil)
      txt =  %{<form accept-charset="UTF-8" action="#{action}"}
      txt << %{ enctype="multipart/form-data"} if multipart
      txt << %{ data-remote="true"} unless local
      txt << %{ class="#{html_class}"} if html_class
      txt << %{ id="#{id}"} if id
      method = method.to_s == "get" ? "get" : "post"
      txt << %{ method="#{method}">}
    end

    def whole_form(action = "/", id = nil, html_class = nil, local: false, **options)
      contents = block_given? ? yield : ""

      method, multipart = options.values_at(:method, :multipart)

      form_text(action, id, html_class, local, multipart, method) + hidden_fields(options.slice :method, :skip_enforcing_utf8) + contents + "</form>"
    end

    def protect_against_forgery?
      false
    end

    def with_locale(testing_locale = :label)
      old_locale, I18n.locale = I18n.locale, testing_locale
      yield
    ensure
      I18n.locale = old_locale
    end
end
