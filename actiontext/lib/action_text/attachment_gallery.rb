# frozen_string_literal: true

module ActionText
  class AttachmentGallery
    include ActiveModel::Model

    TAG_NAME = "div"
    private_constant :TAG_NAME

    class << self
      def fragment_by_canonicalizing_attachment_galleries(content)
        fragment_by_replacing_attachment_gallery_nodes(content) do |node|
          Document.canonicalize_node(node, TAG_NAME)
        end
      end

      def fragment_by_replacing_attachment_gallery_nodes(content)
        Fragment.wrap(content).update do |source|
          find_attachment_gallery_nodes(source).each do |node|
            Document.replace_node(node, yield(node))
          end
        end
      end

      def find_attachment_gallery_nodes(content)
        Fragment.wrap(content).find_all(selector).select do |node|
          Document.node_children(node).all? do |child|
            Document.is_whitespace?(child) ||
              Document.node_matches?(child, attachment_selector)
          end
        end
      end

      def from_node(node)
        new(node)
      end

      def attachment_selector
        "#{ActionText::Attachment.tag_name}[presentation=gallery]"
      end

      def selector
        "#{TAG_NAME}:has(#{attachment_selector} + #{attachment_selector})"
      end
    end

    attr_reader :node

    def initialize(node)
      @node = node
    end

    def attachments
      @attachments ||= Document.find(node, ActionText::AttachmentGallery.attachment_selector).map do |node|
        ActionText::Attachment.from_node(node).with_full_attributes
      end
    end

    def size
      attachments.size
    end

    def inspect
      "#<#{self.class.name} size=#{size.inspect}>"
    end
  end
end
