class Authorization
  def initialize controller
    @controller = controller
  end

  def permissable?
    endpoint.access[action].each do |level|
      return true if send(level)
    end

    false
  end

protected

  def all
    true
  end

  def user
    oauth
  end

  def owner
    find_object.owned_by?(current_user)
  end

  def admin
    current_user.try(:admin?)
  end

private

  def action
    case params[:action]
    when 'show'
      'read'
    when 'index'
      'list'
    when 'update', 'edit'
      'update'
    when 'create', 'new'
      'create'
    when 'destroy'
      'destroy'
    else
      raise 'not possible'
    end
  end

  def oauth
    Doorkeeper::AllDoorkeeperFor.new({}).validate_token(doorkeeper_token)
  end

  def method_missing meth, *args
    @controller.send meth, *args
  end
end
