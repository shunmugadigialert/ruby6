(function() {

QUnit.module('csrf-refresh', {})

QUnit.test('refresh all csrf tokens', function(assert) {
  assert.expect(1)
  var done = assert.async()

  var correctToken = 'cf50faa3fe97702ca1ae'

  var form = $('<form />')
  var input = $('<input>').attr({ type: 'hidden', name: 'authenticity_token', id: 'authenticity_token', value: 'foo' })
  input.appendTo(form)

  $('#qunit-fixture')
    .append('<meta name="csrf-param" content="authenticity_token"/>')
    .append('<meta name="csrf-token" content="' + correctToken + '"/>')
    .append(form)

  $.rails.refreshCSRFTokens()
  currentToken = $('#qunit-fixture #authenticity_token').val()

  assert.equal(currentToken, correctToken)
  done()
})

})()
