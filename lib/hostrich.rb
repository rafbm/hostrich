require 'hostrich/version'

require 'rack'

class Hostrich
  @@hosts = []

  def self.hosts
    @@hosts
  end

  def self.hosts=(array)
    @@hosts = array
  end

  def initialize(app, hosts = [])
    @app = app
    @@hosts += Array(hosts)
  end

  def call(env)
    return @app.call(env) if @@hosts.empty?

    # Extract suffix from current request host.
    match = nil
    @@hosts.detect { |host|
      if http_host = env['HTTP_HOST']
        match = http_host.match(/#{host}(\.[\.\w-]+)?/)
      end
    }
    return @app.call(env) if match.nil?

    suffix = match[1]

    # Fake request host.
    # Eg. If request is made from http://example.com.dev or http://example.com.127.0.0.1.xip.io,
    # the Rack app will see it just as a request to http://example.com.
    env['HTTP_HOST']   = remove_suffix(env['HTTP_HOST'], suffix)
    env['SERVER_NAME'] = remove_suffix(env['SERVER_NAME'], suffix)

    # Get regular response from Rack app
    status, headers, body = @app.call(env)
    body.close if body.respond_to? :close

    chunks = []
    body.each { |chunk| chunks << chunk.to_s }
    body = chunks.join

    # Add current host suffix in all response bodies, so that occurences of http://example.com
    # appear as http://example.com.dev or http://example.com.127.0.0.1.xip.io in the browser.
    body = [add_suffix(body, suffix)]

    # Do the same in response headers. This is important for cookies and redirects.
    headers = Hash[headers.map { |k,v| [k, add_suffix(v, suffix)] }]

    # Return hacked response
    [status, headers, body]
  end

private

  def remove_suffix(input, suffix)
    output = input.dup
    @@hosts.each { |host| output.gsub! "#{host}#{suffix}", host }
    output
  end

  def add_suffix(input, suffix)
    output = input.dup
    # Don’t add suffix when it’s already there. Prevents double-suffix redirects and stuff.
    @@hosts.each { |host| output.gsub! /\b#{host}\b(?!#{suffix})/, "#{host}#{suffix}" }
    output
  end
end
