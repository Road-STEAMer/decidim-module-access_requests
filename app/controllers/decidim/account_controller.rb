# frozen_string_literal: true

module Decidim
  # The controller to handle the user's account page.
  class AccountController < Decidim::ApplicationController
    include Decidim::UserProfile

    helper Decidim::PasswordsHelper
    helper_method :authorized? # Add this line to make the helper method available in views

    def show
      enforce_permission_to :show, :user, current_user: current_user
      
      unless authorized?(current_user)
        flash[:alert] = "You must be authorized to view this page."
        return redirect_to '/authorizations'
      end

      @account = form(AccountForm).from_model(current_user)
    end

    def update
      unless authorized?(current_user)
        flash[:alert] = "You are not authorized to update your account."
        return redirect_to '/authorizations'
      end

      @account = form(AccountForm).from_params(account_params)

      UpdateAccount.call(current_user, @account) do
        on(:ok) do |email_is_unconfirmed|
          flash[:notice] = if email_is_unconfirmed
                             t("account.update.success_with_email_confirmation", scope: "decidim")
                           else
                             t("account.update.success", scope: "decidim")
                           end

          bypass_sign_in(current_user)
          redirect_to account_path(locale: current_user.reload.locale)
        end

        on(:invalid) do |errors|
          flash.now[:alert] = errors.full_messages.to_sentence
          render :show
        end
      end
    end

    def delete
      enforce_permission_to :delete, :user, current_user: current_user
      @form = form(DeleteAccountForm).from_model(current_user)
    end

    def destroy
      enforce_permission_to :delete, :user, current_user: current_user
      @form = form(DeleteAccountForm).from_params(params)

      DestroyAccount.call(current_user, @form) do
        on(:ok) do
          sign_out(current_user)
          flash[:notice] = t("account.destroy.success", scope: "decidim")
        end

        on(:invalid) do
          flash[:alert] = t("account.destroy.error", scope: "decidim")
        end
      end

      redirect_to decidim.root_path
    end

    def resend_confirmation_instructions
      enforce_permission_to :update, :user, current_user: current_user

      ResendConfirmationInstructions.call(current_user) do
        on(:ok) do
          respond_to do |format|
            handle_alert(:success, t("resend_successfully", scope: "decidim.account.email_change", unconfirmed_email: current_user.unconfirmed_email))
            format.js
          end
        end

        on(:invalid) do
          respond_to do |format|
            handle_alert(:alert, t("resend_error", scope: "decidim.account.email_change"))
            format.js
          end
        end
      end
    end

    def cancel_email_change
      enforce_permission_to :update, :user, current_user: current_user

      if current_user.unconfirmed_email
        current_user.update(unconfirmed_email: nil)

        respond_to do |format|
          handle_alert(:success, t("cancel_successfully", scope: "decidim.account.email_change"))
          format.js
        end
      else
        respond_to do |format|
          handle_alert(:alert, t("cancel_error", scope: "decidim.account.email_change"))
          format.js
        end
      end
    end

    private

    def authorized?(user)
      Decidim::Authorization.where(
        decidim_user_id: user.id,
        granted_at: ..Time.current
      ).exists?
    end

    def handle_alert(alert_class, text)
      @alert_class = alert_class
      @text = text
    end

    def account_params
      params[:user].to_unsafe_h
    end
  end
end
