# frozen_string_literal: true

module Admin
  class PatronMetadataValuesController < BaseController
    before_action :require_manage_registrations!
    before_action :set_patron

    def create
      values = apply_change(:add)
      render json: { values: }, status: :created
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      values = apply_change(:remove)
      render json: { values: }
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def set_patron
      @patron = User.find(params[:patron_id])
    end

    def require_manage_registrations!
      require_capability!(:manage_registrations)
    end

    def apply_change(action)
      field = params.require(:field).to_s
      value = params.require(:value).to_s.strip
      raise ArgumentError, "Value can't be blank" if value.blank?

      metadata = (@patron.metadata || {}).deep_dup
      parent = ensure_metadata_path(metadata, field)
      key = path_leaf(field)
      current = Array(parent[key]).reject(&:blank?)

      case action
      when :add
        current << value
      when :remove
        current.delete(value)
      end

      parent[key] = current.uniq
      @patron.update!(metadata: metadata)
      parent[key]
    end

    def ensure_metadata_path(metadata, field)
      path = metadata_path(field)
      leaf_parent = path[0...-1].reduce(metadata) do |memo, key|
        memo[key] ||= {}
      end
      leaf_parent
    end

    def metadata_path(field)
      path = []
      if params[:offering_slug].present?
        path << "offerings" << params[:offering_slug]
      end
      path << field
      path
    end

    def path_leaf(field)
      metadata_path(field).last
    end
  end
end
