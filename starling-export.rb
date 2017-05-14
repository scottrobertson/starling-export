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

def perform_request(path, access_token)
  url = "https://api.starlingbank.com/api/v1#{path}"

  @_requests ||= {}
  @_requests[path] ||= JSON.parse(RestClient.get(url, {:Authorization => "Bearer #{access_token}"}))
end

def transactions(access_token)
  perform_request("/transactions", access_token)['_embedded']['transactions']
end

command :qif do |c|
  c.syntax = 'starling-export qif [options]'
  c.summary = ''
  c.description = ''
  c.option '--directory STRING', String, 'The directory to save this file'
  c.option '--access_token STRING', String, 'The access_token from Starling'
  c.action do |args, options|
    options.default directory: "#{File.dirname(__FILE__)}/tmp"
    path = "#{options.directory}/starling-#{Time.now.to_i}.qif"
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
    path = "#{options.directory}/starling-#{Time.now.to_i}.csv"

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

    puts "Wrote to #{path}"

  end
end
