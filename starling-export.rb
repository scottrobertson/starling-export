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
require 'colorize'
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

      all_transactions = transactions(options.access_token)
      total_count = all_transactions.size

      all_transactions.reverse.each_with_index do |transaction, index|
        amount = (transaction['amount'].to_f).abs.to_s.ljust(6, ' ')
        amount_with_color = transaction['amount'] > 0 ? amount.green : amount.red

        puts "[#{(index + 1).to_s.rjust(total_count.to_s.length) }/#{total_count}] #{Date.parse(transaction['created']).to_s} - #{transaction['id']} - #{amount_with_color}  "

        qif << Qif::Transaction.new(
          date: DateTime.parse(transaction['created']).to_date,
          amount: transaction['amount'],
          memo: nil,
          payee: transaction['narrative']
        )
      end
    end

    puts ""
    puts "Exported to #{path}"
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

      all_transactions = transactions(options.access_token)
      total_count = all_transactions.size

      all_transactions.reverse.each_with_index do |transaction, index|

        amount = (transaction['amount'].to_f).abs.to_s.ljust(6, ' ')
        amount_with_color = transaction['amount'] > 0 ? amount.green : amount.red

        puts "[#{(index + 1).to_s.rjust(total_count.to_s.length) }/#{total_count}] #{Date.parse(transaction['created']).to_s} - #{transaction['id']} - #{amount_with_color}  "

        csv << [
          DateTime.parse(transaction['created']).strftime("%d/%m/%y"),
          transaction['narrative'],
          transaction['amount'],
          transaction['balance']
        ]
      end
    end

    puts ""
    puts "Exported to #{path}"
  end
end

command :balance do |c|
  c.syntax = 'starling-export balance [options]'
  c.summary = ''
  c.option '--access_token STRING', String, 'The access_token from Starling'
  c.action do |args, options|
    account_data = account(options.access_token)
    puts "Account Number: #{account_data['accountNumber']}"
    puts "Sort Code: #{account_data['sortCode']}"
    puts "Balance: £#{balance(options.access_token)}"
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

def account(access_token)
  perform_request("/accounts", access_token)
end
