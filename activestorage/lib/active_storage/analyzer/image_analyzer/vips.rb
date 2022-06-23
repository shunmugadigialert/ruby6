# frozen_string_literal: true

begin
  gem "ruby-vips"
  require "ruby-vips"
rescue LoadError => error
  raise error unless error.message.match?(/ruby-vips/)

  ActiveSupport::Deprecation.warn <<~WARNING
    Setting config.active_storage.variant_processor to :vips without adding
    ruby-vips to the Gemfile is deprecated and will raise in Rails 7.2.

    To fix this warning, set config.active_storage.variant_processor = nil
  WARNING
end

module ActiveStorage
  # This analyzer relies on the third-party {ruby-vips}[https://github.com/libvips/ruby-vips] gem. Ruby-vips requires
  # the {libvips}[https://libvips.github.io/libvips/] system library.
  class Analyzer::ImageAnalyzer::Vips < Analyzer::ImageAnalyzer
    private
      def read_image
        download_blob_to_tempfile do |file|
          image = instrument("vips") do
            ::Vips::Image.new_from_file(file.path, access: :sequential)
          end

          if valid_image?(image)
            yield image
          else
            logger.info "Skipping image analysis because Vips doesn't support the file"
            {}
          end
        end
      rescue ::Vips::Error => error
        logger.error "Skipping image analysis due to an Vips error: #{error.message}"
        {}
      end

      ROTATIONS = /Right-top|Left-bottom|Top-right|Bottom-left/
      def rotated_image?(image)
        ROTATIONS === image.get("exif-ifd0-Orientation")
      rescue ::Vips::Error
        false
      end

      def valid_image?(image)
        image.avg
        true
      rescue ::Vips::Error
        false
      end
  end
end
