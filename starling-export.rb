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
    options.default \
      directory: "#{File.dirname(__FILE__)}/tmp",
      access_token: ENV["STARLING_ACCESS_TOKEN"]

    path = "#{options.directory}/starling.qif"
    Qif::Writer.open(path, type = 'Bank', format = 'dd/mm/yyyy') do |qif|

      all_transactions = transactions(options.access_token)
      total_count = all_transactions.size

      all_transactions.reverse.each_with_index do |transaction, index|

        next if transaction['amount']['minorUnits'] == 0

        payee = transaction['counterPartyName'] || 'Unknown Payee'

        amount = (transaction['amount']['minorUnits'].to_f / 100).abs.to_s.ljust(6, ' ')
        amount_with_color = transaction['amount']['minorUnits'] > 0 ? amount.green : amount.red

        puts "[#{(index + 1).to_s.rjust(total_count.to_s.length) }/#{total_count}] #{Date.parse(transaction['transactionTime']).to_s} - #{transaction['feedItemUid']} - #{amount_with_color} - #{payee}"

        qif << Qif::Transaction.new(
          date: DateTime.parse(transaction['transactionTime']).to_date,
          amount: transaction['amount']['minorUnits'].to_f / 100,
          memo: nil,
          payee: transaction['payee']
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
    options.default \
      directory: "#{File.dirname(__FILE__)}/tmp",
      access_token: ENV["STARLING_ACCESS_TOKEN"]

    path = "#{options.directory}/starling.csv"

    CSV.open(path, "wb") do |csv|
      csv << [:date, :description, :amount, :balance]

      all_transactions = transactions(options.access_token)

      total_count = all_transactions.size

      all_transactions.reverse.each_with_index do |transaction, index|
        next if transaction['amount']['minorUnits'] == 0

        payee = transaction['counterPartyName'] || 'Unknown Payee'

        amount = (transaction['amount']['minorUnits'].to_f / 100).abs.to_s.ljust(6, ' ')
        amount_with_color = transaction['amount']['minorUnits'] > 0 ? amount.green : amount.red

        puts "[#{(index + 1).to_s.rjust(total_count.to_s.length) }/#{total_count}] #{Date.parse(transaction['transactionTime']).to_s} - #{transaction['feedItemUid']} - #{amount_with_color} - #{payee}"

        csv << [
          DateTime.parse(transaction['transactionTime']).strftime("%d/%m/%y"),
          payee,
          transaction['amount']['minorUnits'].to_f / 100,
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
    options.default \
      access_token: ENV["STARLING_ACCESS_TOKEN"]

    account_data = account(options.access_token)
    account_info = account_info(options.access_token, account_data['accountUid'])
    balance_data = balance(options.access_token, account_data['accountUid'])

    puts "Account Number: #{account_info['accountIdentifier']}"
    puts "Sort Code: #{account_info['bankIdentifier']}"
    puts "Balance: £#{balance_data['amount']['minorUnits'].to_f / 100}"
  end
end

def perform_request(path, access_token)
  url = "https://api.starlingbank.com/api/v2#{path}"
  JSON.parse(RestClient.get(url, {:Authorization => "Bearer #{access_token}"}))
end

def transactions(access_token)
  account = account(access_token)
  perform_request("/feed/account/#{account['accountUid']}/category/#{account['defaultCategory']}?changesSince=2015-01-01T00:00:00.000Z", access_token)['feedItems']
end

def balance(access_token, account_id)
  perform_request("/accounts/#{account_id}/balance", access_token)
end

def account_info(access_token, account_id)
  perform_request("/accounts/#{account_id}/identifiers", access_token)
end

def account(access_token)
  perform_request("/accounts", access_token)['accounts'].first
end
