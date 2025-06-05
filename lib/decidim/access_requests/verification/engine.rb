# frozen_string_literal: true

module Decidim
  module AccessRequests
    module Verification
      # This is an engine that performs user authorization.
      class Engine < ::Rails::Engine
        isolate_namespace Decidim::AccessRequests::Verification
        paths["db/migrate"] = nil

        routes do
          resource :authorizations, only: [:new, :create, :edit], as: :authorization do
            get :renew, on: :collection
          end

          root to: "authorizations#new"
        end

        initializer "decidim.access_requests.register_verification_workflow" do
          Decidim::Verifications.register_workflow(:your_requests) do |workflow|
            workflow.engine = Decidim::AccessRequests::Verification::Engine
            workflow.admin_engine = Decidim::AccessRequests::Verification::AdminEngine
            workflow.renewable = true
            workflow.time_between_renewals = 5.minutes
          end
        end

        initializer "decidim.access_requests.load_locales" do |app|
          locales_path = root.join("config", "locales", "**", "*.yml")
          config.i18n.load_path += Dir[locales_path.to_s]
        end

        initializer "decidim.access_requests.register_icons" do
          Decidim.icons.register(
            name: "envelope-closed",
            icon: "envelope-closed",
            category: "system",
            description: "Closed envelope icon",
            engine: :access_requests
          )
        
          Decidim.icons.register(
            name: "check",
            icon: "check",
            category: "system",
            description: "Check icon",
            engine: :access_requests
          )
        
          Decidim.icons.register(
            name: "bell",
            icon: "bell",
            category: "system",
            description: "Notification bell icon",
            engine: :access_requests
          )
        end
        
        

        def load_seed
          # Enable the `:access_requests` authorization
          org = Decidim::Organization.first
          org.available_authorizations << :access_requests
          org.save!
        end
      end
    end
  end
end
