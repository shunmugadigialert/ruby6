# frozen_string_literal: true

module ActionController # :nodoc:
  module ContentSecurityPolicy
    # TODO: Documentation
    extend ActiveSupport::Concern

    include AbstractController::Helpers
    include AbstractController::Callbacks

    included do
      helper_method :content_security_policy?
      helper_method :content_security_policy_nonce
    end

    module ClassMethods
      def content_security_policy(enabled = true, **options, &block)
        before_action(options) do
          if block_given?
            policy = current_content_security_policy
            yield policy
            request.content_security_policy = policy
          end

          unless enabled
            request.content_security_policy = nil
          end
        end
      end

      def content_security_policy_report_only(enabled = true, **options, &block)
        before_action(options) do
          if block_given?
            if current_content_security_policy_report_only == true
              policy = ActionDispatch::ContentSecurityPolicy.new
            else
              policy = current_content_security_policy_report_only
            end

            yield policy
            request.content_security_policy_report_only = policy
          else
            request.content_security_policy_report_only = true
          end

          unless enabled
            request.content_security_policy_report_only = nil
          end
        end
      end
    end

    private
      def content_security_policy?
        request.content_security_policy
      end

      def content_security_policy_nonce
        request.content_security_policy_nonce
      end

      def current_content_security_policy
        request.content_security_policy&.clone || ActionDispatch::ContentSecurityPolicy.new
      end

      def current_content_security_policy_report_only
        request.content_security_policy_report_only&.clone || ActionDispatch::ContentSecurityPolicy.new
      end
  end
end
