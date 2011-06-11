require 'cases/helper'
require 'models/person'

class ActiveModelI18nTests < ActiveModel::TestCase

  def setup
    I18n.backend = I18n::Backend::Simple.new
  end

  def test_translated_model_attributes
    I18n.backend.store_translations 'en', :activemodel => {:attributes => {:person => {:name => 'person name attribute'} } }
    assert_equal 'person name attribute', Person.human_attribute_name('name')
  end

  def test_translated_model_attributes_with_default
    I18n.backend.store_translations 'en', :attributes => { :name => 'name default attribute' }
    assert_equal 'name default attribute', Person.human_attribute_name('name')
  end

  def test_translated_model_attributes_using_default_option
    assert_equal 'name default attribute', Person.human_attribute_name('name', :default => "name default attribute")
  end

  def test_translated_model_attributes_using_default_option_as_symbol
    I18n.backend.store_translations 'en', :default_name => 'name default attribute'
    assert_equal 'name default attribute', Person.human_attribute_name('name', :default => :default_name)
  end

  def test_translated_model_attributes_falling_back_to_default
    assert_equal 'Name', Person.human_attribute_name('name')
  end

  def test_translated_model_attributes_using_default_option_as_symbol_and_falling_back_to_default
    assert_equal 'Name', Person.human_attribute_name('name', :default => :default_name)
  end

  def test_translated_model_attributes_with_symbols
    I18n.backend.store_translations 'en', :activemodel => {:attributes => {:person => {:name => 'person name attribute'} } }
    assert_equal 'person name attribute', Person.human_attribute_name(:name)
  end

  def test_translated_model_attributes_with_ancestor
    I18n.backend.store_translations 'en', :activemodel => {:attributes => {:child => {:name => 'child name attribute'} } }
    assert_equal 'child name attribute', Child.human_attribute_name('name')
  end

  def test_translated_model_attributes_with_ancestors_fallback
    I18n.backend.store_translations 'en', :activemodel => {:attributes => {:person => {:name => 'person name attribute'} } }
    assert_equal 'person name attribute', Child.human_attribute_name('name')
  end

  def test_translated_model_attributes_with_attribute_matching_namespaced_model_name
    I18n.backend.store_translations 'en', :activemodel => {:attributes => {:person => {:gender => 'person gender'}, :"person/gender" => {:attribute => 'person gender attribute'}}}

    assert_equal 'person gender', Person.human_attribute_name('gender')
    assert_equal 'person gender attribute', Person::Gender.human_attribute_name('attribute')
  end

  def test_translated_model_names
    I18n.backend.store_translations 'en', :activemodel => {:models => {:person => 'person model'} }
    assert_equal 'person model', Person.model_name.human
  end

  def test_translated_model_names_with_sti
    I18n.backend.store_translations 'en', :activemodel => {:models => {:child => 'child model'} }
    assert_equal 'child model', Child.model_name.human
  end

  def test_translated_model_names_with_ancestors_fallback
    I18n.backend.store_translations 'en', :activemodel => {:models => {:person => 'person model'} }
    assert_equal 'person model', Child.model_name.human
  end

  def test_human_does_not_modify_options
    options = {:default => 'person model'}
    Person.model_name.human(options)
    assert_equal({:default => 'person model'}, options)
  end
  
  def test_alternate_namespaced_model_attribute_translation
    I18n.backend.store_translations 'en', :activemodel => {:attributes => {:person => {:gender => {:attribute => 'person gender attribute'}}}}
    assert_equal 'person gender attribute', Person::Gender.human_attribute_name('attribute')
  end

  def test_alternate_namespaced_model_translation
    I18n.backend.store_translations 'en', :activemodel => {:models => {:person => {:gender => 'person gender model'}}}
    assert_equal 'person gender model', Person::Gender.model_name.human
  end

  def test_alternate_namespaced_model_error_translation
    with_test_translations_loaded do
      post = Blog::Post.new
      post.valid?
      assert_equal "can't be blank - dot notation", post.errors.get(:title).first    # both notations exist 
      assert_equal "can't be blank - dot notation", post.errors.get(:header).first   # only dot notation exists
      assert_equal "can't be blank - slash notation", post.errors.get(:editor).first # only slash notation exists
    end
  end


  private

  def with_test_translations_loaded
    yaml_file = File.dirname(__FILE__) + '/translation_test.yml'
    I18n.load_path << yaml_file
    yield if block_given?
    I18n.load_path.delete(yaml_file)
  end
end

