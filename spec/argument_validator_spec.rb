# frozen_string_literal: true

require 'rspec'
require_relative '../argument_validator.rb'

describe ArgumentValidator do
  describe 'Usage' do
    before(:each) { allow(Sysexits).to receive(:exit) }

    it 'displays usage for an incorrect number of arguments' do
      validator = ArgumentValidator.new('usage', 1)
      expect { validator.check_number_of_arguments([]) }.to(
        output("usage\n").to_stdout
      )
    end

    it 'does not display usage with the correct number of arguments' do
      validator = ArgumentValidator.new('usage', 2)
      expect { validator.check_number_of_arguments(['foo', 1]) }.to_not(
        output("usage\n").to_stdout
      )
    end
  end
end
