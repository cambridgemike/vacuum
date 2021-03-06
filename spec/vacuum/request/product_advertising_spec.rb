require 'spec_helper'

module Vacuum
  module Request
    describe ProductAdvertising do
      let(:mock_response) do
        Response::ProductAdvertising.new '', 200
      end

      let(:request) do
        described_class.new do |config|
          config.key = 'key'
          config.secret = 'secret'
          config.tag = 'tag'
        end
      end

      it_behaves_like 'a request'

      describe '#look_up' do
        before do
          request.stub!(:get).and_return mock_response
        end

        let(:parameters) do
          request.parameters
        end

        context 'given no items' do
          it 'raises an error' do
            expect { request.look_up }.to raise_error ArgumentError
          end
        end

        context 'given up to 10 items' do
          before do
            request.look_up *((1..10).to_a << { :foo => 'bar' })
          end

          it 'builds a single-batch query' do
            parameters['ItemId'].split(',').should =~ (1..10).map(&:to_s)
          end

          it 'takes parameters' do
            parameters['Foo'].should eql 'bar'
          end
        end

        context 'given 11 to to 20 items' do
          before do
            request.look_up *((1..20).to_a << {
              :foo => 'bar',
              :version => 'baz'
            })
          end

          it 'builds a multi-batch query' do
            first = parameters['ItemLookup.1.ItemId'].split(',')
            second = parameters['ItemLookup.2.ItemId'].split(',')
            (first + second).should =~ (1..20).map(&:to_s)
          end

          it 'takes parameters' do
            parameters['ItemLookup.Shared.Foo'].should eql 'bar'
          end

          it 'overrides version' do
            parameters['Version'].should eql 'baz'
          end
        end

        context 'given over 20 items' do
          it 'raises an error' do
            expect { request.look_up *(1..21) }.to raise_error ArgumentError
          end
        end
      end

      describe '#search' do
        let(:parameters) do
          request.parameters
        end

        before do
          request.stub!(:get).and_return mock_response
        end

        context 'when given a search index and a keyword' do
          before do
            request.search :foo, 'bar'
          end

          it 'builds a keyword search' do
            parameters['Keywords'].should eql 'bar'
          end

          it 'sets the search index' do
            parameters['SearchIndex'].should eql 'Foo'
          end
        end

        context 'when given a search index and parameters' do
          before do
            request.search(:foo, :bar => 'baz')
          end

          it 'sets the parameters' do
            parameters['Bar'].should eql 'baz'
          end

          it 'sets the search index' do
            parameters['SearchIndex'].should eql 'Foo'
          end
        end
      end
    end
  end
end
