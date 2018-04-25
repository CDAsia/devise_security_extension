module Devise
  class IpAuthenticationsController < ::DeviseController
    prepend_before_action :require_no_authentication, only: :show

    def show
      resource_for_remote_ip
      return redirect_to new_session_path(resource_name) unless resource && resource.active_for_authentication?
      yield resource if block_given?
      respond_with(resource, serialize_options)
    end

    private

    def resource_for_remote_ip
      self.resource = resource_class.find_for_ip_authentication({}, request.remote_ip)
    end

    def serialize_options
      methods = resource_class.authentication_keys.dup
      methods = methods.keys if methods.is_a?(Hash)
      { methods: methods }
    end
  end
end
