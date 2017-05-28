#!/usr/bin/env ruby

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rubygems'
require 'commander/import'
require 'rest-client'
require 'json'
require 'csv'
require 'yaml'
require 'qif'
require 'starling/export/version'

program :name, 'starling-export'
program :version, Starling::Export::VERSION
program :description, 'Generate QIF or CSV from Starling'

command :qif do |c|
  c.syntax = 'starling-export qif [options]'
  c.summary = ''
  c.description = ''
  c.option '--directory STRING', String, 'The directory to save this file'
  c.option '--access_token STRING', String, 'The access_token from Starling'
  c.action do |args, options|
    options.default directory: "#{File.dirname(__FILE__)}/tmp"
    path = "#{options.directory}/starling.qif"
    Qif::Writer.open(path, type = 'Bank', format = 'dd/mm/yyyy') do |qif|
      transactions(options.access_token).each do |transaction|
        qif << Qif::Transaction.new(
          date: DateTime.parse(transaction['created']).to_date,
          amount: transaction['amount'],
          memo: nil,
          payee: transaction['narrative']
        )
      end
    end

    puts "Balance: £#{balance(options.access_token)}"
    puts "Wrote to #{path}"
  end
end

command :csv do |c|
  c.syntax = 'starling-export csv [options]'
  c.summary = ''
  c.description = ''
  c.option '--directory STRING', String, 'The directory to save this file'
  c.option '--access_token STRING', String, 'The access_token from Starling'
  c.action do |args, options|
    options.default directory: "#{File.dirname(__FILE__)}/tmp"
    path = "#{options.directory}/starling.csv"

    CSV.open(path, "wb") do |csv|
      csv << [:date, :description, :amount, :balance]
      transactions(options.access_token).reverse.each_with_index do |transaction, index|
        csv << [
          DateTime.parse(transaction['created']).strftime("%d/%m/%y"),
          transaction['narrative'],
          transaction['amount'],
          transaction['balance']
        ]
      end
    end

    puts "Balance: £#{balance(options.access_token)}"
    puts "Wrote to #{path}"
  end
end

def perform_request(path, access_token)
  url = "https://api.starlingbank.com/api/v1#{path}"
  JSON.parse(RestClient.get(url, {:Authorization => "Bearer #{access_token}"}))
end

def transactions(access_token)
  perform_request("/transactions", access_token)['_embedded']['transactions']
end

def balance(access_token)
  perform_request("/accounts/balance", access_token)['availableToSpend']
end
