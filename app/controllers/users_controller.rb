class UsersController < ApplicationController

	before_filter :authenticate_user!


	def index
		unless can? :index, User
			return redirect_to current_user, alert: "You aren't allowed to list users."
		end

		@superset = User.order(last_name: :asc)
		@unapproved, @users = [], []

		@superset.each do |user|
			if user.role == "Unapproved"
				@unapproved << user
			else
				@users << user
			end
		end
	end


	def show
		@user = User.find(params[:id])

		unless can? :view, @user
			return redirect_to root_url, alert: "You aren't allowed to view this profile."
		end

		@organizations = @user.organizations

		if @user.role == "Creative"
			@orders = Order.where(creative_id: @user.id).limit(5)
		else
			@orders = Order.where(owner_id: @user.id).limit(5)
		end
	end


	def edit
		@user = User.find(params[:id])

		unless can? :edit, @user
			return redirect_to @user, alert: "You aren't allowed to edit this profile."
		end
	end


	def update
		@user = User.find(params[:id])

		unless can? :edit, @user
			return redirect_to @user, alert: "You aren't allowed to edit this profile."
		end

		if params[:user][:password].blank?
			params[:user].delete(:password)
			params[:user].delete(:password_confirmation)

			if @user.update_attributes(user_params)
				redirect_to @user, notice: "Profile updated successfully."
			else
				render :edit
			end

		else
			if @user.update_attributes(user_params)
				sign_in(current_user, :bypass => true) if current_user.id == @user.id
				redirect_to @user, notice: "Password updated."
			else
				render :edit
			end
		end
	end


	def destroy
		@user = User.find(params[:id])

		unless can? :destroy, @user
			return redirect_to root_url, alert: "You aren't allowed to delete this user."
		end

		if @user.destroy
			redirect_to users_path, notice: "User deleted."
		else
			redirect_to @user, alert: "Error: User could not be deleted."
		end
	end


	private
		def user_params
			if can? :manage, User
				params.require(:user).permit!
			else
				params.require(:user).permit(:first_name,
					:last_name, :email, :phone,
					:password, :password_confirmation)
			end
		end
end