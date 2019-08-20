class AssertionPolicy < Struct.new(:user, :assertion)
  def update?
    Role.user_is_at_least_a?(user, :editor)
  end

  def propose?
    user
  end

  def destroy?
    Role.user_is_at_least_a?(user, :editor)
  end

  def accept?
    Role.user_is_at_least_a?(user, :editor) && assertion.submitter != user
  end

  def reject?
    Role.user_is_at_least_a?(user, :editor) || assertion.submitter == user
  end
end
