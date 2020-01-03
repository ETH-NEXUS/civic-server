class NotifySubscribers < ApplicationJob
  def perform(event)
    subscriptions_by_user = aggregate_direct_subscriptions(Hash.new { |h, k| h[k] = {} }, event.subject)
    subscriptions_by_user = aggregate_meta_subscriptions(subscriptions_by_user, event)
    subscriptions_by_user.values.flat_map(&:values).each do |subscription|
      subscription.send_notification(event) unless subscription.user == event.originating_user
    end
  end

  private
  def aggregate_direct_subscriptions(user_hash, subscribable)
    user_hash.tap do |h|
      subscribable_with_parents = EventHierarchy.new(subscribable).parents
      subscribable_with_parents.each do |curr|
        curr.subscriptions.each do |sub|
          h[sub.user_id][sub.type] ||= sub
        end
      end
    end
  end

  def aggregate_meta_subscriptions(user_hash, event)
    user_hash.tap do |h|
      Subscription.meta_subscriptions_for_event(event).each do |subscription|
        h[subscription.user_id][subscription.type] ||= subscription
      end
    end
  end
end
