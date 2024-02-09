# a simple/configurable rake task that generates some random fake data for the app (using faker) at various sizes
# based on gist from @nowaterlili: https://gist.github.com/nowaterlili/2531386
# Attention: This is only intended for UI/UX testing purposes and currently still requires some manual changes in the test instance.
# Changes necessary/Requirements in system:
# - Disable request sending out messages to contributors - safety precaution to not accidentally send a message to one of the randomly generated mail addresses
#     - Comment out line 27 'after_create { Request.broadcast!(self) }' in request.rb
# - Requires some users to already be registered in the system, requests are assigned randomly to already existing users
# - Disable (comment out) validations that are hard to mock
#     - e.g. raw_data presence validation in message.rb
require 'faker'
require 'open-uri'

class Fakeout

    # Attention: disable request sending or validations that are hard to mock in the codebase
    MODELS = %w(Request Contributor Message)

    # define a build method for each model, returning a list of attributes for Model.create! calls
    def build_contributor
      {
        :first_name => Faker::Name.first_name,
        :last_name => Faker::Name.last_name,
        :email => Faker::Internet.email,
        :data_processing_consent => true,
        :note => Faker::Movies::HitchhikersGuideToTheGalaxy.quote,
      }
    end

    def build_request
        question_time = Faker::Time.backward(days: 14)
        { :title            => Faker::Lorem.question,
          :text             => Faker::Lorem.paragraph,
          :created_at       => question_time,
          :updated_at       => question_time,
          :user_id          => User.all.map(&:id).sample(),
          :broadcasted_at   => question_time,
        }
    end

    def build_message
        message_time = Faker::Time.backward(days: 14)
        { :request_id       => Request.all.map(&:id).sample(),
          :text             => Faker::Lorem.paragraph,
          :created_at       => message_time,
          :updated_at       => message_time,
          :broadcasted      => false,
          :sender_id        => Contributor.all.map(&:id).sample(),
          :sender_type      => "Contributor",
          :unknown_content  => false,
        }
    end

    def post_fake
        # called after faking out, use this method for additional updates or additions
        Contributor.all.each do |currentContributor|
            image = URI.open(Faker::Avatar.image(size: "50x50", format: "png", set:"set5"))
            currentContributor.avatar.attach(
                io: image,
                filename: 'fake-image.png'
            )
        end
    end

    # number contributors
    def tiny
        10
    end

    def small
        50
    end

    def medium
        500
    end

    def large
        1000
    end

    # END Customizing

    attr_accessor :size

    def initialize(size)
        self.size = size
    end

    def builder_for(model)
        "build_#{model.downcase}".parameterize.underscore
    end

    def fakeout
        puts "Faking it ... (#{size})"
        Fakeout.disable_mailers
        MODELS.each do |model|
            if !respond_to?(builder_for(model))
                puts "  * #{model.pluralize}: **warning** I couldn't find a #{builder_for(model)} method"
                next
            end
            model_size = send(size)
            if model == "Request"
                model_size = 14
            elsif model == "Message"
                model_size = 14 * 0.5 * model_size
            end
            #contributor size is not changed

            1.upto(model_size) do
                attributes = send(builder_for(model))
                model.constantize.create!(attributes) if attributes && !attributes.empty?
            end
            puts "  * #{model.pluralize}: #{model.constantize.count(:all)}"
        end
        post_fake
        puts "Done, I faked it!"
    end

    def self.clean
        puts "Cleaning all ..."
        Fakeout.disable_mailers
        MODELS.each do |model|
            model.constantize.destroy_all
        end
    end

    # by default, all mailings are disabled on faking out
    def self.disable_mailers
        ActionMailer::Base.perform_deliveries = false
    end


    private
end


# the tasks, hook to class above - use like so;
# rake fakeout:clean
# rake fakeout:medium RAILS_ENV=development
#.. etc.
namespace :fakeout do

    desc "clean away all data"
    task :clean => :environment do |t, args|
        Fakeout.clean
    end

    desc "fake out a tiny dataset"
    task :tiny => :clean do |t, args|
        Fakeout.new(:tiny).fakeout
    end

    desc "fake out a small dataset"
    task :small => :clean do |t, args|
        Fakeout.new(:small).fakeout
    end

    desc "fake out a medium dataset"
    task :medium => :clean do |t, args|
        Fakeout.new(:medium).fakeout
    end

    desc "fake out a large dataset"
    task :large => :clean do |t, args|
        Fakeout.new(:large).fakeout
    end
end
