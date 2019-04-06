# frozen_string_literal: true

module Spotlight
  module Resources
    ##
    # OpenGraph metadata harvester
    module OpenGraph
      extend ActiveSupport::Concern
      include Spotlight::Resources::Web

      def opengraph
        @opengraph ||= begin
          page = {}

          body.css('meta').select { |m| m.attribute('property') }.each do |m|
            page[m.attribute('property').to_s] = m.attribute('content').to_s
          end

          page
        end
      end

      def opengraph_properties
        opengraph.transform_keys do |k|
          "#{opengraph_solr_field_name(k)}_tesim"
        end
      end

      private

      def opengraph_solr_field_name(field)
        field.parameterize(separator: '_')
      end
    end
  end
end
