class GenePolicy < Struct.new(:user, :gene)
  include PolicyHelpers

  def create?
    user
  end

  def update?
    Role.user_is_at_least_a?(user, :admin)
  end

  def destroy?
    Role.user_is_at_least_a?(user, :admin)
  end
end
