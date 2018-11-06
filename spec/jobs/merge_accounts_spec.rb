require 'spec_helper'
require 'rails_helper'

describe 'merging accounts' do
  it 'should merge subscriptions' do
    remaining_user = Fabricate(:user)
    subsumed_user = Fabricate(:user)
    gene = Fabricate(:gene)
    OnSiteSubscription.create(user: remaining_user, subscribable: gene)
    OnSiteSubscription.create(user: remaining_user, action_type: 'commented', action_class: 'Gene')
    OnSiteSubscription.create(user: subsumed_user, subscribable: gene)
    OnSiteSubscription.create(user: subsumed_user, action_type: 'commented', action_class: 'Gene')
    OnSiteSubscription.create(user: subsumed_user, action_type: 'commented', action_class: 'Variant')

    MergeAccounts.new.perform(remaining_user, subsumed_user)

    expect(Subscription.count).to eq 3
    expect(remaining_user.subscriptions.count).to eq 3
  end

  it 'should transfer events' do
    remaining_user = Fabricate(:user)
    subsumed_user = Fabricate(:user)
    gene = Fabricate(:gene)
    Event.create(
      action: '1',
      originating_user: remaining_user,
      subject: gene
    )
    Event.create(
      action: '2',
      originating_user: subsumed_user,
      subject: gene
    )

    MergeAccounts.new.perform(remaining_user, subsumed_user)

    Event.all.each do |e|
      expect(e.originating_user).to eq(remaining_user)
    end
  end

  it 'should transfer notifications' do
    remaining_user = Fabricate(:user)
    subsumed_user = Fabricate(:user)

    notified = Notification.create(
      notified_user: subsumed_user,
      originating_user: Fabricate(:user),
    )

    originating = Notification.create(
      originating_user: subsumed_user,
      notified_user: Fabricate(:user),
    )

    MergeAccounts.new.perform(remaining_user, subsumed_user)

    expect(notified.reload.notified_user).to eq(remaining_user)
    expect(originating.reload.originating_user).to eq(remaining_user)

  end

  it 'should transfer suggested changes' do
    remaining_user = Fabricate(:user)
    subsumed_user = Fabricate(:user)

    SuggestedChange.create(
      user: subsumed_user,
      suggested_changes: { test: 'test' },
      moderated: Fabricate(:gene)
    )

    MergeAccounts.new.perform(remaining_user, subsumed_user)

    expect(SuggestedChange.first.user).to eq(remaining_user)
  end

  it 'it should keep the highest role' do
    remaining_user = Fabricate(:user)
    subsumed_user = Fabricate(:user)

    subsumed_user.make_admin!

    MergeAccounts.new.perform(remaining_user, subsumed_user)

    expect(remaining_user.admin?).to be true
  end

  it 'should merge authorizations' do
    remaining_user = Fabricate(:user)
    subsumed_user = Fabricate(:user)

    Authorization.create(user: remaining_user, provider: 'provider1', uid: '1')
    Authorization.create(user: subsumed_user, provider: 'provider1', uid: '1')
    Authorization.create(user: subsumed_user, provider: 'provider1', uid: '2')

    expect(remaining_user.authorizations.count).to be 1
    expect(subsumed_user.authorizations.count).to be 2

    MergeAccounts.new.perform(remaining_user, subsumed_user)

    expect(remaining_user.authorizations.count).to be 2
  end

  it 'should transfer comments' do
    remaining_user = Fabricate(:user)
    subsumed_user = Fabricate(:user)
    gene = Fabricate(:gene)
    Comment.create(commentable: gene, user: remaining_user, title: 'blah', text: 'blah')
    Comment.create(commentable: gene, user: subsumed_user, title: 'blah', text: 'blah')

    MergeAccounts.new.perform(remaining_user, subsumed_user)

    expect(Comment.count).to eq 2
    expect(Comment.where(user: remaining_user).count).to eq 2
    expect(Comment.where(user_id: subsumed_user.id).count).to eq 0
  end

  it 'should transfer revisions' do
    remaining_user = Fabricate(:user)
    subsumed_user = Fabricate(:user)
    gene = Fabricate(:gene)
    Audited.audit_class.as_user(subsumed_user) do
      gene.name = 'new name'
      gene.save
    end

    expect(Audited.audit_class.where(user: subsumed_user).count).to eq 1
    expect(Audited.audit_class.where(user: remaining_user).count).to eq 0

    MergeAccounts.new.perform(remaining_user, subsumed_user)

    expect(Audited.audit_class.where(user: subsumed_user).count).to eq 0
    expect(Audited.audit_class.where(user: remaining_user).count).to eq 1
  end

  it 'should remove the old user' do
    remaining_user = Fabricate(:user)
    subsumed_user = Fabricate(:user)

    MergeAccounts.new.perform(remaining_user, subsumed_user)

    expect(User.where(id: subsumed_user.id).exists?).to be false
  end
end
