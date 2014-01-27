      class ApiController < ApplicationController
  before_action :find_object, only: [:show, :update, :destroy]
  skip_before_filter :verify_authenticity_token

  rescue_from(ActionController::RoutingError) do
    render json: { error_message: "The resource you were looking for does not exist" }, status: 404
  end

  def show
    singleton_response
  end

  def update
    permitted_params = []

    endpoint_attributes.each do |attr, val|
      if val.is_a? Hash
        permitted_params << { attr => params[attr].try(:keys) || [] }
      else
        permitted_params << attr
      end
    end

    @object.attributes = params.permit(*permitted_params)

    if @object.save
      singleton_response
    else
      render json: {
        error: @object.errors
      }
    end
  end

  def create
    @object = scope.new
    update
  end

protected

  def singleton_response
    methods = endpoint_attributes.keys

    render json: {
      object: @object.as_json(root: false, only: [], methods: (methods << 'uid'))
    }
  end

  def endpoint_attributes
    Quill::API.endpoints[params[:endpoint]]['attributes']
  end

  def find_object
    @object = scope.find_by_uid!(params[:id])
  end

  def scope
    @scope ||= case params[:endpoint]
    when 'activities'
      ActivityClassification.find_by_uid!(params[:cid]).activities
    else
      params[:endpoint].singularize.camelize.constantize
    end
  end

  # rescue_from(Exception) do |e|
  #   binding.pry
  #   render json: { error_message: "We're sorry, but something went wrong. We've been notified about this issue and we'll take a look at it shortly." }, status: 500
  # end
end