# frozen_string_literal: true

module Api
  module V1
    class TemplesController < Api::BaseController
      def show
        render json: TempleSerializer.new(current_temple).as_json
      end
    end
  end
end
