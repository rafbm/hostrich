# Hostrich

Hostrich is a Rack middleware that eases multi-domain web app development.

## Usage

Add the middleware at the top of your development stack, passing it the domain(s) your app is using:

```ruby
# Gemfile
gem 'hostrich', group: :development
```

```ruby
# config.ru

# if using Rack::Deflater, put it here
if ENV['RACK_ENV'] == 'development'
  use Hostrich, ['somedomain.com', 'otherdoma.in']
end
# ... any other middleware ...

run Your::RackApp
```

## Database-dynamic hosts

If your app serves pages on hosts that depend on models, say a `Website` model with a `custom_domain` column, you can append hosts to the `Hostrich.hosts` array after your app intialization:

```ruby
# config/environments/development.rb

config.after_initialize do
  Hostrich.hosts += Website.pluck(:custom_domain).compact
end
```

## Rationale

Hostrich tricks your development environment into thinking it is serving your application from your production host (`example.com`) instead of your usual development host (`example.dev`).

Thus, your application doesn’t have to know about any dev-prod hosts mapping. This makes your code simpler and less prone to errors.

To make this possible, you must access your local app at `http://example.com.dev` or the like, where a suffix is added to the full production domain. This way Hostrich can extract `.dev` from the host and append it everywhere `example.com` is output in your response bodies and headers.

[xip.io](http://xip.io) is Hostrich’s best friend. For complex multi-domain web apps like ours at [Medalist](http://medali.st), it’s a must. Our app responds to `medali.st`, `manage.medali.st`, `*.mli.st` and even `anydomain.com` because some of our users have custom domains. xip.io allows us to access our local app at:

- **medali.st**.127.0.0.1.xip.io
- **manage.medali.st**.127.0.0.1.xip.io
- **mikaelkingsbury.mli.st**.127.0.0.1.xip.io
- **mikaelkingsbury.ca**.127.0.0.1.xip.io

And our application code only knows about production hosts:

```ruby
# config/routes.rb

Medalist::Application.routes.draw do
  # http://medali.st/
  namespace :public, host: 'medali.st' do
    # ...
  end

  # http://manage.medali.st/
  namespace :manage, host: 'manage.medali.st' do
    # ...
  end

  # http://usersite.mli.st/
  # http://usersite.com/
  namespace :usersite do
    # ...
  end
end
```

## TODO

- This README isn’t that great.

---

© 2014 [Rafaël Blais Masson](http://medali.st). Hostrich is released under the MIT license.
