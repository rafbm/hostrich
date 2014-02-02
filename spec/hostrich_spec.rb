require 'spec_helper'

describe Hostrich do
  # Prevent spec mess-up after testing `Hostrich.hosts += ['...']`
  before { Hostrich.hosts = [] }

  let(:app) {
    proc { |env|
      case env['PATH_INFO']
      when '/redirect'
        [302, { 'Location' => 'http://foo.com/index.html' }, []]
      when '/cookie'
        [200, { 'Set-Cookie' => 'some_param=foo.com/index.html; Path=/; Domain=.foo.com' }, ['Cookie!']]
      else
        [200, {}, ['Welcome to foo.com or foo.com.dev, not foo.comzle, not ffoo.com and not bar.io']]
      end
    }
  }
  let(:request) { Rack::MockRequest.new(stack) }

  shared_examples 'the whole deal' do
    it 'adds host suffix in response body' do
      response = request.get('/', 'HTTP_HOST' => 'foo.com.dev')
      expect(response.body).to eq 'Welcome to foo.com.dev or foo.com.dev, not foo.comzle, not ffoo.com and not bar.io'
    end

    it 'adds host suffix in response headers' do
      response = request.get('/redirect', 'HTTP_HOST' => 'foo.com.dev')
      expect(response.headers['Location']).to eq 'http://foo.com.dev/index.html'

      response = request.get('/cookie', 'HTTP_HOST' => 'foo.com.dev')
      expect(response.headers['Set-Cookie']).to eq 'some_param=foo.com.dev/index.html; Path=/; Domain=.foo.com.dev'
    end
  end

  context 'passing host as a string' do
    let(:stack) { Hostrich.new(app, 'foo.com') }
    it_behaves_like 'the whole deal'
  end

  context 'passing host as an array' do
    let(:stack) { Hostrich.new(app, ['foo.com']) }
    it_behaves_like 'the whole deal'
  end

  context 'passing multiple hosts as an array' do
    let(:stack) { Hostrich.new(app, %w[foo.com foo.bar.io]) }
    it_behaves_like 'the whole deal'

    it 'adds host suffix for all hosts' do
      response = request.get('/', 'HTTP_HOST' => 'foo.com.127.0.0.1.xip.io')
      expect(response.body).to eq 'Welcome to foo.com.127.0.0.1.xip.io or foo.com.127.0.0.1.xip.io.dev, not foo.comzle, not ffoo.com and not bar.io'
    end
  end

  context 'passing no host' do
    let(:stack) { Hostrich.new(app) }

    it 'does nothing' do
      response = request.get('/', 'HTTP_HOST' => 'foo.com.dev')
      expect(response.body).to eq 'Welcome to foo.com or foo.com.dev, not foo.comzle, not ffoo.com and not bar.io'
    end

    context 'adding hosts after initialization' do
      before { Hostrich.hosts += ['foo.com'] }
      it_behaves_like 'the whole deal'
    end
  end
end
