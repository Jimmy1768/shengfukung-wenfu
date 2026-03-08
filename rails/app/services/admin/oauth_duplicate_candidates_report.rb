# frozen_string_literal: true

module Admin
  class OAuthDuplicateCandidatesReport
    Entry = Struct.new(
      :verified_email,
      :user_ids,
      :providers,
      :identities,
      keyword_init: true
    ) do
      def user_count
        user_ids.size
      end
    end

    def entries
      groups.filter_map do |verified_email, identities|
        user_ids = identities.map(&:user_id).uniq
        next if user_ids.size < 2

        Entry.new(
          verified_email: verified_email,
          user_ids: user_ids,
          providers: identities.map(&:provider).uniq.sort,
          identities: identities.sort_by { |identity| [identity.last_login_at || Time.at(0), identity.updated_at] }.reverse
        )
      end.sort_by { |entry| [-entry.user_count, entry.verified_email.to_s] }
    end

    private

    def groups
      verified_identities
        .group_by { |identity| identity.email.to_s.downcase.strip }
        .reject { |email, _| email.blank? }
    end

    def verified_identities
      OAuthIdentity
        .includes(:user)
        .where(email_verified: true)
        .where.not(email: [nil, ""])
    end
  end
end
