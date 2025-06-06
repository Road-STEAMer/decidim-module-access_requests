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

        initializer "decidim.access_requests.add_cells_view_paths" do
          Cell::ViewModel.view_paths.unshift(
            File.expand_path("#{Decidim::AccessRequests::Verification::Engine.root}/app/cells")
          )
        end

        
      initializer "access_requests.icons" do
        # Registra l'icona envelope-closed usando una RemixIcon
        Decidim.icons.register(
          name: "envelope-closed",
          icon: "mail-send-line", # Oppure "mail-unread-line" per icona chiusa alternativa
          category: "system",
          description: "Closed envelope icon",
          engine: :core
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
