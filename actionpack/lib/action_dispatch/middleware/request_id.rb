# frozen_string_literal: true

# :markup: markdown

require "securerandom"
require "active_support/core_ext/string/access"

module ActionDispatch
  # # Action Dispatch RequestId
  #
  # Makes a unique request id available to the `action_dispatch.request_id` env
  # variable (which is then accessible through ActionDispatch::Request#request_id
  # or the alias ActionDispatch::Request#uuid) and sends the same id to the client
  # via the `X-Request-Id` header.
  #
  # The unique request id is either based on the `X-Request-Id` header in the
  # request, which would typically be generated by a firewall, load balancer, or
  # the web server, or, if this header is not available, a random uuid. If the
  # header is accepted from the outside world, we sanitize it to a max of 255
  # chars and alphanumeric and dashes only.
  #
  # The unique request id can be used to trace a request end-to-end and would
  # typically end up being part of log files from multiple pieces of the stack.
  class RequestId
    SANITIZER = ->(request_id) { request_id.gsub(/[^\w\-@]/, "") }
    mattr_accessor :sanitizer, instance_writer: false, default: SANITIZER

    def initialize(app, header:)
      @app = app
      @header = header
      @env_header = "HTTP_#{header.upcase.tr("-", "_")}"
    end

    def call(env)
      req = ActionDispatch::Request.new env
      req.request_id = make_request_id(req.get_header(@env_header))
      @app.call(env).tap { |_status, headers, _body| headers[@header] = req.request_id }
    end

    private
      def make_request_id(request_id)
        request_id.present? ? sanitizer.(request_id).first(255) : internal_request_id
      end

      def internal_request_id
        SecureRandom.uuid
      end
  end
end
