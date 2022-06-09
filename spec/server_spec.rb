# frozen_string_literal: true

require 'rack'
require 'puma'
require "open-uri"

RSpec.describe 'Test' do
  let(:configru) do
    <<~CONFIGRU
      app = ->(_env) { [200, {}, ["Hello, world!"]] }
      
      run app
    CONFIGRU
  end
  it "can request from a forked process" do
    begin
      pid = fork do
        $stdout.reopen "/dev/null", "a"
        $stderr.reopen "/dev/null", "a"
        system("rackup -b '#{configru}'")
      end

      response = open_uri("http://0.0.0.0:9292")

      expect(response).to eq("Hello, world!")
    ensure
      Process.kill(:KILL, pid)
    end
  end

  def open_uri(uri, attempts = 5)
    URI.open(uri).read
  rescue Errno::ECONNREFUSED => e
    raise if attempts.zero?

    sleep 1
    open_uri(uri, attempts - 1)
  end
end
