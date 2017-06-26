require 'spec_helper'

describe Hostrich do
  # Prevent spec mess-up after testing `Hostrich.hosts += ['...']`
  before { Hostrich.hosts = [] }

  let(:app) {
    proc { |env|
      case env['PATH_INFO']
      when '/redirect'
        [302, { 'Location' => 'http://foo.com/index.html' }, []]
      when '/origin'
        [200, {}, [env['HTTP_ORIGIN'] == 'http://foo.com' ? 'right' : 'wrong']]
      when '/referer'
        [200, {}, [env['HTTP_REFERER'] == 'http://foo.com' ? 'right' : 'wrong']]
      when '/cookie'
        [200, { 'Set-Cookie' => 'some_param=foo.com/index.html; Path=/; Domain=.foo.bar.io' }, ['Cookie!']]
      when '/version.rb'
        Rack::File.new('lib/hostrich').call(env)
      else
        [200, {}, ['Welcome to foo.com, foo.com.dev or foo.bar.io, not foo.comzle, not ffoo.com and not bar.io']]
      end
    }
  }
  let(:request) { Rack::MockRequest.new(stack) }

  shared_examples 'adds suffix to single host' do
    it 'adds host suffix in response headers' do
      response = request.get('/redirect', 'HTTP_HOST' => 'foo.com.dev')
      expect(response.headers['Location']).to eq 'http://foo.com.dev/index.html'

      response = request.get('/cookie', 'HTTP_HOST' => 'foo.com.dev')
      expect(response.headers['Set-Cookie']).to eq 'some_param=foo.com.dev/index.html; Path=/; Domain=.foo.bar.io'

      response = request.get('/origin', 'HTTP_HOST' => 'foo.com.dev', 'HTTP_ORIGIN' => 'http://foo.com.dev')
      expect(response.body).to eq 'right'

      response = request.get('/referer', 'HTTP_HOST' => 'foo.com.dev', 'HTTP_REFERER' => 'http://foo.com.dev')
      expect(response.body).to eq 'right'
    end

    it 'works with Rack::File' do
      response = request.get('/version.rb', 'HTTP_HOST' => 'foo.com.dev')
      expect(response.body).to include "class Hostrich\n  VERSION"
    end

    it 'adds host suffix in response body' do
      response = request.get('/', 'HTTP_HOST' => 'foo.com.dev')
      expect(response.body).to eq 'Welcome to foo.com.dev, foo.com.dev or foo.bar.io, not foo.comzle, not ffoo.com and not bar.io'
    end

    it 'processes request successfully if no HTTP_HOST present' do
      response = request.get('/')
      expect(response.body).to eq 'Welcome to foo.com, foo.com.dev or foo.bar.io, not foo.comzle, not ffoo.com and not bar.io'
    end
  end

  context 'passing host as a string' do
    let(:stack) { Hostrich.new(app, 'foo.com') }
    include_examples 'adds suffix to single host'
  end

  context 'passing host as an array' do
    let(:stack) { Hostrich.new(app, ['foo.com']) }
    include_examples 'adds suffix to single host'
  end

  context 'passing multiple hosts as an array' do
    let(:stack) { Hostrich.new(app, %w[foo.com foo.bar.io]) }

    it 'adds host suffix to multiple hosts in response headers' do
      response = request.get('/redirect', 'HTTP_HOST' => 'foo.com.dev')
      expect(response.headers['Location']).to eq 'http://foo.com.dev/index.html'

      response = request.get('/cookie', 'HTTP_HOST' => 'foo.com.dev')
      expect(response.headers['Set-Cookie']).to eq 'some_param=foo.com.dev/index.html; Path=/; Domain=.foo.bar.io.dev'
    end

    it 'adds host suffix to multiple hosts in response body' do
      response = request.get('/', 'HTTP_HOST' => 'foo.com.127.0.0.1.xip.io')
      expect(response.body).to eq 'Welcome to foo.com.127.0.0.1.xip.io, foo.com.127.0.0.1.xip.io.dev or foo.bar.io.127.0.0.1.xip.io, not foo.comzle, not ffoo.com and not bar.io'
    end
  end

  context 'passing no host' do
    let(:stack) { Hostrich.new(app) }

    it 'does nothing' do
      response = request.get('/', 'HTTP_HOST' => 'foo.com.dev')
      expect(response.body).to eq 'Welcome to foo.com, foo.com.dev or foo.bar.io, not foo.comzle, not ffoo.com and not bar.io'
    end

    context 'adding hosts after initialization' do
      before { Hostrich.hosts += ['foo.com'] }
      include_examples 'adds suffix to single host'
    end
  end
end
