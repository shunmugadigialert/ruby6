require 'abstract_unit'
require 'active_support/core_ext/class/attribute'

class ClassAttributeTest < ActiveSupport::TestCase
  def setup
    @klass = Class.new { class_attribute :setting }
    @sub = Class.new(@klass)
  end

  test 'defaults to nil' do
    assert_nil @klass.setting
    assert_nil @sub.setting
  end

  test 'inheritable' do
    @klass.setting = 1
    assert_equal 1, @sub.setting
  end

  test 'overridable' do
    @sub.setting = 1
    assert_nil @klass.setting

    @klass.setting = 2
    assert_equal 1, @sub.setting

    assert_equal 1, Class.new(@sub).setting
  end

  test 'query method' do
    assert_equal false, @klass.setting?
    @klass.setting = 1
    assert_equal true, @klass.setting?
  end

  test 'instance reader delegates to class' do
    assert_nil @klass.new.setting

    @klass.setting = 1
    assert_equal 1, @klass.new.setting
  end

  test 'instance override' do
    object = @klass.new
    object.setting = 1
    assert_nil @klass.setting
    @klass.setting = 2
    assert_equal 1, object.setting
  end

  test 'instance query' do
    object = @klass.new
    assert_equal false, object.setting?
    object.setting = 1
    assert_equal true, object.setting?
  end

  test 'disabling instance writer' do
    object = Class.new { class_attribute :setting, :instance_writer => false }.new
    assert_raise(NoMethodError) { object.setting = 'boom' }
  end

  test 'disabling instance reader' do
    object = Class.new { class_attribute :setting, :instance_reader => false }.new
    assert_raise(NoMethodError) { object.setting }
    assert_raise(NoMethodError) { object.setting? }
  end

  test 'disabling both instance writer and reader' do
    object = Class.new { class_attribute :setting, :instance_accessor => false }.new
    assert_raise(NoMethodError) { object.setting }
    assert_raise(NoMethodError) { object.setting? }
    assert_raise(NoMethodError) { object.setting = 'boom' }
  end

  test 'disabling inherited persistence' do
    base_class = Class.new { class_attribute :setting, :persist_when_inherited => false ; self.setting = "value" }
    inherited_class = Class.new(base_class)
    assert_equal "value", base_class.setting
    assert_equal nil, inherited_class.setting
  end

  test 'works well with singleton classes' do
    object = @klass.new
    object.singleton_class.setting = 'foo'
    assert_equal 'foo', object.setting
  end

  test 'setter returns set value' do
    val = @klass.send(:setting=, 1)
    assert_equal 1, val
  end
end
