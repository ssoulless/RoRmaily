# RoRmaily

RoRmaily is a Ruby on Rails gem that helps you sending and managing your mailings. Think of RoRMaily as a self-hosted Mailchimp alternative you can easily integrate with your site and that uses Amazon SES for send your bulk emails. RoRmaily aims to use the power of Amazon SES and others of the familiy of AWS for emailmarketing, since it is wide powerful and cheap than other alternatives, there are other solutions that use Amazon SES however non of them are open source and charge fees, we want people with basic technical knowledge enjoy their emailmerking for free with this Open Source tool.

With RoRmaily you can send:
* one-time mailings (i.e. welcome emails, special offers),
* periodical mailings (i.e. weekly notifications, reminders),
* mailing sequences - multiple ordered emails delivered with certain delays since specific point in time (i.e. onboarding emails, site feature overview).

Maily keeps track of user subscriptions and allow them to easily opt out. You can define who receives which emails and specify conditions that control delivery. All deliveries are tracked and logged. Periodical and Sequence mailing deliveries are scheduled individually for each recipient.

Maily seamlessly integrates with your app. It can use your regular Mailers or you can build ad-hoc mailings with [Liquid](http://liquidmarkup.org/) markup templates. 

Core Maily features are accessible for Rails programmers via API. Apart from that, we are planning to create a web UI provided by separate into another gem that we will call **ror_maily-webui**

###Contents
* [Requirements](https://github.com/ssoulless/RoRmaily#requirements)
* [Installation](https://github.com/ssoulless/RoRmaily#installation)
* [Features](https://github.com/ssoulless/RoRmaily#features)
* [Development state](https://github.com/ssoulless/RoRmaily#development-state)
* [Updating](https://github.com/ssoulless/RoRmaily#updating)
* [How it works](https://github.com/ssoulless/RoRmaily#how-it-works)
* [Usage](https://github.com/ssoulless/RoRmaily#usage)
  * [Migrations](https://github.com/ssoulless/RoRmaily#migrations)
  * [Defaults](https://github.com/ssoulless/RoRmaily#defaults-optional)
  * [Initializer](https://github.com/ssoulless/RoRmaily#initializer)
  * [Mailers](https://github.com/ssoulless/RoRmaily#mailers)
  * [Opt-outs](https://github.com/ssoulless/RoRmaily#opt-outs)
  * [Delivery](https://github.com/ssoulless/RoRmaily#opt-outs)
  * [Background processing](https://github.com/ssoulless/RoRmaily#background-processing)
* [Configuring](https://github.com/ssoulless/RoRmaily#configuring)
* [Deployments](https://github.com/ssoulless/RoRmaily#deployments)
* [Opt-out URLs](https://github.com/ssoulless/RoRmaily#opt-out-urls)
* [Redis namespaces](https://github.com/ssoulless/RoRmaily#redis-namespaces)
* [Contributing](https://github.com/ssoulless/RoRmaily#contributing)
* [More Information](https://github.com/ssoulless/RoRmaily#more-information)
* [License](https://github.com/ssoulless/RoRmaily#license)

## Requirements

Both Ruby on Rails 3.2 and 4 are supported. 

## Installation

Simply just

    gem install ror_maily

or put in your Gemfile

    gem "ror_maily"

## Features

* Designed for Ruby on Rails
* Designed for work with Amazon SES
* Self-hosted
* Seamless and flexible integration
* Asynchronous processing
* Individual delivery scheduling 
* Great both for developers (API) and end-users (Web UI) 
* Ad-hoc email templating using [Liquid](http://liquidmarkup.org/) syntax
* Three different mailing types
* User-friendly subscription management i.e. via automatic & personal opt-out links
* Correspondence logging
* Mailing conditions

## Development state

There is not a Stable release of RoRmaily, and its mayor main features are not ready yet, like Amazon SES integration, right now it is using local mailer for send bulk email, we want to achieve in the near future to integrate bulk email delivery using Amazon SES.

The other key feature for ynchronous processing is the integraiton with Amazon SQS, right now RoRmaily uses a local Redis server along with Sidekiq for background job processing, the goal is to let that work to Amazon Queues (SQS).

Once the main features are ready we want to add some other features that we have not planned in our priorities.

Here are some things we would like to implement in the future:

* better mailing scheduling,
* message analytics,
* link tracking,
* better Web UI,
* _put your beloved feature here_.

## Updating
See [release notes](RELEASE_NOTES.md) for information about what has changed and if actions are needed to upgrade, and if you want to know how we are versioning the gem please see [naming conventions](VERSIONING_CONVENTIONS.md)

## How it works

There are few key concepts that need to be explained in order to understand how Maily works. Some of them are similar to what you might know form other conventional email marketing software. Others come strictly from Ruby on Rails world.

**Entities**

Entities are basically your mailing recipients. They will be probably represented in your application by `User` model.

**Mailings**

You usually send single emails to your users - one at a time. Mailing is a bunch of emails sent out to many users. RoRmaily allows you to send three types of Mailings: one-times, periodicals and sequences.

**Contexts**

Maily Contexts are abstraction layer for accessing collections of entities and their attributes. 

There are three main things that Contexts do:

* They define sets of entities via Rails scopes (i.e. `User.activated` meaning all application users that activated their accounts). 
* They specify destination email addresses for entities (i.e. you can define that `User#email` method returns email address or specify a custom proc that does that).
* They specify additional entity attributes that can be used inside Mailing templates, conditions etc. (basically - attributes accessible via Liquid).

**Lists and Subscriptions**

Lists are sets of entities that receive certain mailings. Entities are added to Lists by creating Subscriptions. It is entirely up to you how you manage subscriptions in application. Typically, you put some checkbox in user's profile page that subscribes and unsubscribes them from mailing lists.

Each Subscription has it's unique token allowing users to be provided with one click opt-out link.

**Mailers**

Mailers are standard way of sending emails in Rails applications. RoRmaily hooks into ActionMailer internals and allows you to send Mailings just like you send your regular emails. All you need to do is inherit `RoRmaily::Mailer` in your Mailer. 

There's also a possibility to send Mailings without using any of your custom Mailers. `RoRmaily::Mailer` is in this case used implicitly; email body and subject is stored directly in your Mailing definition as a Liquid template. Liquid gives you access to entity attributes defined in the Context. This way of creating Mailings is especially useful within Web UI where you can build new Mailing by just typing its template.

**Delivery**

RoRmaily uses great gem [Sidekiq](http://sidekiq.org/) to process deliveries in the background. This applies to Periodical and Sequence Mailings - their delivieries are scheduled individually for each entity on the subscription list. 

Maily needs to check periodically for scheduled mailings and if their time come - queue them for delivery. This is job for RoRmaily Paperboy - tiny daemon that runs in the background and check the schedules. It is essential to make you periodical and sequence mailings work.

## Usage

Let's assume your entities are your `User` model objects. Read on in order to find out how to start with Maily.

### Migrations

Install engine migrations and run them.

```ruby
rake ror_maily:install:migrations
rake db:migrate
```

### Defaults (optional)

In some cases, you need to specify default `from` and `host` mailer options in order to ensure proper email rendering:

```ruby
config.action_mailer.default_options = { from: "hello@RoRmaily.org" }
config.action_mailer.default_url_options = { host: "RoRmaily.org" }

```

### Initializer

Generate and setup an initializer.

```ruby
rails g ror_maily:install
```

This will create the following file:

```ruby
# config/initializers/ror_maily.rb
RoRmaily.setup do |config|
  # Put your contexts, mailing definitions etc. here.
end
```

There are few things you need to put there. 

**Set up your context**

Say for example, you want to deliver your mailings to all your active users:

```ruby
config.context :active_users do |context|
  context.scope {User.active}
  context.destination {|user| user.email}
  
  # Alternatively, you can specify destination as attribute name:
  # context.destination = :email
end
```

**Set up your lists**

Following means that all users in `:active_users` context scope can be subscribed to `:newsletters` list.

```ruby
config.list :notifications do |list|
  list.context_name = :active_users
end

config.list :newsletters do |list|
  list.context_name = :active_users
end
```

**Set up your mailings**

```ruby
config.one_time_mailing :hello do |mailing|
  mailing.title = "Hello mailing"
  mailing.list = :notifications
  mailing.mailer_name = "UserMailer"
  mailing.enable # mailings are disabled by default
end

config.periodical_mailing :weekly_newsletter do |mailing|
  mailing.title = "Weekly newsletter"
  mailing.list = :newsletters
  mailing.mailer_name = "UserMailer"
  mailing.enable
end
```

### Mailers

You don't need to have any Mailer to use RoRmaily. It works perfectly fine with its generic `RoRmaily::Mailer` and mailing templates written in Liquid. 

But if you still want your fancy Mailer views and features, you need to modify it a bit.

First, each Mailer you want to use with RoRmaily needs to extend `RoRmaily::Mailer` class. 
Then each Mailer method must be named after mailing identification name and accept only one parameter which is your entity (i.e. `User` class object).

This setup gives you some extra instance variables available in your views:

* `@maily_entity` - entity you are sending this email to,
* `@maily_mailing` - Mailing you are sending,
* `@maily_subscription` - `RoRmaily::Subscription` object related to this entity and Mailing,

Here's the complete example:

```ruby
class UserMailer < RoRmaily::Mailer
  def hello user
    mail :subject => "Hi there #{user.name}!"
  end
end
```

### Opt-outs

RoRmaily allows entities to easily opt-out using direct unsubscribe urls. Each entity subscription has its own token and based on this token, opt-out URL is generated.

To process user opt-out requests you need to mount Maily into your app:

```ruby
# config/routes.rb

mount RoRmaily::Engine => "/unsubscribe", :as => "ror_maily_engine"
```

Maily provides you with URL helper that generates opt-out URLs (i.e. in your ActionMailer views):

```ruby
ror_maily_engine.unsubscribe_url(@maily_subscription)
```

When you use Liquid for email templating, you should use following syntax:
```
{{subscription.token_url}}
```

Visiting opt-out url disables subscription and by default redirects to "/".

### Delivery

From now on, Maily will handle and track your regular mail deliveries:

```ruby
UserMailer.hello(User.first).deliver
```

Of course, you can also run the mailing for all users in scope at once:

```ruby
RoRmaily.dispatch(:hello).run
```

See [API Docs](http://www.rubydoc.info/github/ssoulless/RoRmaily) for more details about delivery methods.

### Background processing

Start RoRmaily Paperboy which will take care of your other periodical and sequence deliveries:

```
$ ror_maily paperboy --start
```

**That's it!**

Your Maily setup is now complete.

## Configuring

You can configure your Maily using config file `config/ror_maily.yml`. Supported options:

* `verbose`: true,false
* `logfile`: where all the stuff is logged, usually 'log/ror_maily.log`
* `pidfile`: file name
* `redis_url`: string
* `redis_namespace`: string
* `redis_driver`: string

## Other stuff

### Deployments

Maily has some simple support for Capistrano built-in. It supports both v2 and v3 and automates the task of starting, stopping and restarting Paperboy daemon during deployments.

To enable, just put following line into your `Capfile`:

```ruby
require 'ror_maily/capistrano'
```

### Opt-out URLs

By default, visiting opt-out URL disables subscription and redirects to "/". You can easily customize the redirect path by specifying `token_redirect` proc:

```ruby
# Evaluated within config:
config.token_redirect do |controller, subscription|
  # This is just an example, put here whatever you want.
  controller.view_context.unsubscribed_path
end
```

In case you need more customization, you can always overwrite `RoRmaily::TokensController` and its `get` method:

```ruby
# app/controllers/ror_maily/tokens_controller.rb
module RoRmaily
  class TokensController < ::ApplicationController
    before_action :find_subscription

    def get
      if @subscription && @subscription.active?
        @subscription.deactivate!
        # now render some custom view
      else
        redirect_to(main_app.root_url)
      end
    end

    private

    def find_subscription
      @subscription ||= RoRmaily::Subscription.find_by_token(params[:token])
    end
  end
end
```

### Redis namespaces

If you want to use RoRmaily with non-standard Redis namespace, make sure your Sidekiq is also configured properly. This usually involves creating initializer file:

```ruby
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { namespace: 'maily' }
end
Sidekiq.configure_client do |config|
  config.redis = { namespace: 'maily' }
end
```

Then of course you need to tell Maily about that too:

```yaml
# config/ror_maily.yml
---
:redis_namespace: maily
```

## Contributing

Would you like to help in the development of RoRmaily? [Follow these steps](CONTRIBUTING.md).

## More Information

* [API Docs](http://www.rubydoc.info/github/ssoulless/RoRmaily)
* For bug reports or feature requests see the [issues on Github](https://github.com/ssoulless/RoRmaily/issues).  

## License

LGPLv3 License. Copyright 2015

Initial development sponsored by University of Quindio (http://uniquindio.edu.co)

## Credits

* Based and inspired in [MailyHerald](https://github.com/Sology/maily_herald). Seeking to merge RoRmaily features with MailyHerald in a near future.
* Documentation Structure based on [Sharetribe](https://github.com/sharetribe/sharetribe) Docs templates.