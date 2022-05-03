# == Schema Information
#
# Table name: teams
#
#  id                :bigint           not null, primary key
#  allow_auto_assign :boolean          default(TRUE)
#  description       :text
#  name              :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#
# Indexes
#
#  index_teams_on_account_id           (account_id)
#  index_teams_on_name_and_account_id  (name,account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class Team < ApplicationRecord
  belongs_to :account
  has_many :team_members, dependent: :destroy_async
  has_many :members, through: :team_members, source: :user
  has_many :conversations, dependent: :nullify

  validates :name,
            presence: { message: 'must not be blank' },
            uniqueness: { scope: :account_id }

  before_validation do
    self.name = name.downcase if attribute_present?('name')
  end

  def add_member(user_id)
    team_members.find_or_create_by(user_id: user_id)&.user
  end

  def remove_member(user_id)
    team_members.find_by(user_id: user_id)&.destroy!
  end

  def messages
    account.messages.where(conversation_id: conversations.pluck(:id))
  end

  def reporting_events
    account.reporting_events.where(conversation_id: conversations.pluck(:id))
  end
end