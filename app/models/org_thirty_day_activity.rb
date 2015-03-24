class OrgThirtyDayActivity < ActiveRecord::Base
  SORT_TYPES = [['All Organizations', 'all_orgs'], %w(Commercial commercial), %w(Education educational),
                %w(Government government), %w(Non-Profit non_profit), %w(Large large),
                %w(Medium medium), %w(Small small)]

  FILTER_TYPES = { all_orgs: :filter_all_orgs, small: :filter_small_orgs, medium: :filter_medium_orgs,
                   large: :filter_large_orgs, commercial: :filter_commercial_orgs,
                   government: :filter_government_orgs, non_profit: :filter_non_profit_orgs,
                   educational: :filter_educational_orgs }

  belongs_to :organization

  scope :filter_all_orgs, -> { with_thirty_day_commit_count }
  scope :filter_small_orgs, -> { with_thirty_day_commit_count.where(project_count: 1..10) }
  scope :filter_medium_orgs, -> { with_thirty_day_commit_count.where(project_count: 11..50) }
  scope :filter_large_orgs, -> { with_thirty_day_commit_count.where(arel_table[:project_count].gt(50)) }
  scope :filter_commercial_orgs, -> { with_thirty_day_commit_count.where(org_type: 1) }
  scope :filter_educational_orgs, -> { with_thirty_day_commit_count.where(org_type: 2) }
  scope :filter_government_orgs, -> { with_thirty_day_commit_count.where(org_type: 3) }
  scope :filter_non_profit_orgs, -> { with_thirty_day_commit_count.where(org_type: 4) }

  class << self
    def most_active_orgs
      commits_per_affliate = (arel_table[:thirty_day_commit_count] / arel_table[:affiliate_count])
      with_commits_and_affiliates
        .select([Arel.star, commits_per_affliate.as('commits_per_affiliate')])
        .order(commits_per_affliate.desc).limit(3)
    end

    def filter(filter_type)
      filter_type = filter_type.to_sym
      fail ArgumentError, 'Invalid Filter Type' unless FILTER_TYPES.keys.include?(filter_type)
      send(FILTER_TYPES[filter_type])
    end

    private

    def with_commits_and_affiliates
      orgs = Organization.arel_table
      joins(:organization)
        .where(id: orgs[:thirty_day_activity_id])
        .where(arel_table[:thirty_day_commit_count].gt(0)
        .and(arel_table[:affiliate_count].gt(0)))
    end

    def with_thirty_day_commit_count
      orgs = Organization.arel_table
      joins(:organization)
        .where(id: orgs[:thirty_day_activity_id])
        .where.not(thirty_day_commit_count: nil)
        .order(thirty_day_commit_count: :desc)
        .limit(5)
    end
  end
end