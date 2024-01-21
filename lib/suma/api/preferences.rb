# frozen_string_literal: true

require "grape"

require "suma/api"

class Suma::API::Preferences < Suma::API::V1
  include Suma::API::Entities

  resource :preferences do
    helpers do
      def update_preferences(member)
        params[:subscriptions].each do |k, optin|
          k = k.to_sym
          invalid!("subscription value #{k} must be a bool") unless Suma.bool?(optin)
          subscr = member.preferences!.subscriptions.find { |g| g.key == k && g.editable? }
          invalid!("subscription #{k} is invalid") if subscr.nil?
          subscr.set_from_opted_in(optin)
        end
        member.preferences.save_changes
      end
    end

    resource :public do
      helpers do
        def member!
          prefs = Suma::Message::Preferences[access_token: params[:access_token]]
          unauthenticated! if prefs.nil?
          unauthenticated! if prefs.member.soft_deleted?
          return prefs.member
        end
      end
      params do
        requires :access_token, type: String
      end
      get do
        member = member!
        present member, with: PublicPrefsMemberEntity
      end

      params do
        requires :access_token, type: String
        requires :subscriptions, type: Hash
      end
      post do
        member = member!
        update_preferences(member)
        status 200
        present member, with: PublicPrefsMemberEntity
      end
    end

    params do
      requires :subscriptions, type: Hash
    end
    post do
      member = current_member
      update_preferences(member)
      status 200
      present member, with: CurrentMemberEntity
    end
  end

  class PublicPrefsEntity < BaseEntity
    expose :subscriptions, with: Suma::API::Entities::PreferencesSubscriptionEntity
  end

  class PublicPrefsMemberEntity < BaseEntity
    expose :masked_email, as: :email
    expose :masked_name, as: :name
    expose :masked_phone, as: :phone
    expose :preferences!, as: :preferences, with: PublicPrefsEntity
  end
end
