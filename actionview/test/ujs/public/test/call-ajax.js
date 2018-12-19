(function() {

QUnit.module('call-ajax', {
  beforeEach: function() {
    $('#qunit-fixture')
      .append($('<a />', { href: '#' }))
  }
})

QUnit.test('call ajax without "ajax:beforeSend"', function(assert) {
  var done = assert.async()

  var link = $('#qunit-fixture a')
  link.bindNative('click', function() {
    Rails.ajax({
      type: 'get',
      url: '/',
      success: function() {
        assert.ok(true, 'calling request in ajax:success')
      }
    })
  })

  link.triggerNative('click')
  setTimeout(function() { done() }, 50)
})

})()
