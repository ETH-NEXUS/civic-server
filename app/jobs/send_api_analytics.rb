class SendApiAnalytics < ApplicationJob
  def perform(args = {})
    tracker = Staccato.tracker(Constants::GA_TRACKING_ID, nil, ssl: true)
    tracker.pageview(args)
  end
end