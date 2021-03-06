require 'spec_helper'

describe User do
  #pending "add some examples to (or delete) #{__FILE__}"
    before do
        @user = User.new(name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar")
    #password_confirmation is another required variable
    end

    subject {@user}

    it {should respond_to(:name)}
    it {should respond_to(:email)}
    it {should respond_to(:password_digest)} #password_digest is a required column name!!!
    it {should respond_to(:password)}
    it {should respond_to(:password_confirmation)}
    it {should respond_to(:authenticate)}
    it {should respond_to(:admin_md)} #for creatino of admin user types
    it {should respond_to(:microposts)} #testing an association between user and microposts
    it {should respond_to(:feed)}
    it {should respond_to(:relationships)}
    it {should respond_to(:followed_users)}
    it {should respond_to(:following?)}
    it {should respond_to(:follow!)}
    it {should respond_to(:reverse_relationships)}
    it {should respond_to(:followers)}



    it {should be_valid}
    it {should_not be_admin_md} # for creation of admin user types

    describe "with admin attribute set to 'true' " do
        before do
            @user.save!
            @user.toggle!(:admin_md) # toggle comes from Rails
        end
        it { should be_admin_md }
    end

    describe "when name is not present" do
        before {@user.name = " "}
        it {should_not be_valid}
    end

    describe "when email is not present" do
        before {@user.email = " "}
        it {should_not be_valid}
    end

    describe "when name is too long" do
        before { @user.name = "a" * 51 }
        it { should_not be_valid }
    end

    describe "when email format is invalid" do
        it "should be invalid" do
            addresses = %w[user@foo,com user_at_foo.org example.user@foo. foo@bar_baz.com foo@bar+baz.com foo@bar..com]

            addresses.each do |invalid_address|
                @user.email = invalid_address
                expect(@user).not_to be_valid
            end
        end
    end

    describe "when email format is valid" do
        it "should be valid" do
            addresses = %w[user@foo.COM A_US-ER@f.b.org first.last@foo.jp a+b@baz.cn]
            addresses.each do |valid_address|
                @user.email = valid_address
                expect(@user).to be_valid
            end
        end
    end

    describe "when email address is already taken" do
        before do
            user_with_same_email = @user.dup
            user_with_same_email.email = @user.email.upcase
            user_with_same_email.save
        end

        it {should_not be_valid}
    end

    describe "when password is not present" do
        before do
            @user = User.new(name: "Example User", email: "user@example.com", password: " ", password_confirmation: " ")
        end
        it {should_not be_valid}
    end

    describe "when password doesn't match confirmation" do
        before {@user.password_confirmation = "mismatch"}
        it {should_not be_valid}

    end

    describe "return value of authenticate method" do
        before { @user.save }  #first, save the user to the DB so we can find it later

        let (:found_user) {User.find_by(email: @user.email)} #Repect uses 'let' to create local variables using : notation

        describe "with valid password" do
            it {should eq found_user.authenticate(@user.password)} #eq is the same as ==
        end

        describe "with invalid password" do
            let (:user_for_invalid_password) {found_user.authenticate("invalid")}
            it {should_not eq user_for_invalid_password}
            specify {expect(user_for_invalid_password).to be_false}
        end

    end

    describe "with a password that's too short" do
        before {@user.password = @user.password_confirmation = "a" * 5}
        it {should be_invalid}

    end

    describe "email address with mixed case" do
        let(:mixed_case_email) {"Foo@ExaMPle.CoM"}

        it "should be saved as all locwer-case" do
            @user.email = mixed_case_email
            @user.save
            expect(@user.reload.email).to eq mixed_case_email.downcase
        end

    end

    it { should respond_to(:password_confirmation) }
    it { should respond_to(:remember_token) }
    it { should respond_to(:authenticate) }

    describe "remember token" do
        before { @user.save }
        its(:remember_token) { should_not be_blank }
    end

    describe "microposts associations" do
        before { @user.save }
        # let! forces the corresponding variables to come into existence immediately,
        # so that the timestamps are in the right order and the @user.microposts isn't ready.
        # let, however, is a _lazy_ variable, meaning they come into existence only when referenced.

        let!(:older_micropost) do
            FactoryGirl.create(:micropost, user: @user, created_at: 1.day.ago)
        end

        let!(:newer_micropost) do
            FactoryGirl.create(:micropost, user: @user, created_at: 1.hour.ago)
        end

        it "should have the right microposts in the right order" do
            expect(@user.microposts.to_a).to eq [newer_micropost, older_micropost]
        end

        it "should destroy associated microposts" do
            microposts = @user.microposts.to_a # this call (to_a) effectively makes a copy of the micropost (i.e., captures them in a local variable)
            @user.destroy
            expect(microposts).not_to be_empty # after having destroyed the user, the test checks that the local variable is not empty. This is a safety check to catch any errors should the to_a ever be accidently removed
            # without the to_a, destriying the user will destroy the posts in the microsoft variable, and the loop below will not test properly.
            microposts.each do |micropost|
                # check that a micropost with a given id does not exist in a DB
                expect(Micropost.where(id: micropost.id)).to be_empty
            end
        end

        describe "status" do
            let(:unfollowed_post) do
                FactoryGirl.create(:micropost, user: FactoryGirl.create(:user))
            end

            let(:followed_user) { FactoryGirl.create(:user) }

            before do
                @user.follow!(followed_user)
                3.times {followed_user.microposts.create!(content: "Lorem ipsum")}
            end

            its(:feed) { should include(newer_micropost) }
            its(:feed) { should include(older_micropost) }
            its(:feed) { should_not include(unfollowed_post)}

            its(:feed) do
                followed_user.microposts.each do |micropost|
                    should include(micropost)
                end
            end
        end

    end

    describe "following" do
        let(:other_user) {FactoryGirl.create(:user)}
        before do
            @user.save
            @user.follow!(other_user)
        end

        it {should be_following(other_user)}
        its(:followed_users) {should include(other_user)}

        describe "followed user" do
            subject {other_user}
            its(:followers) {should include(@user)}
        end

        describe "and unfollowing" do
            before {@user.unfollow!(other_user)}
            it {should_not be_following(other_user)}
            its(:followed_users) {should_not include(other_user)}
        end
    end


end


















