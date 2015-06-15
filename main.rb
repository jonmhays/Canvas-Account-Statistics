#!/usr/bin/ruby
# encoding: UTF-8

require 'rubygems'
require 'yaml'
require 'httparty'
require 'csv'
require 'json'

# Get Account Statistics for a list of accounts from the Canvas-LMS
class Find_Account_Stats
  include HTTParty
  # debug_output

  def initialize
    @config = YAML.load_file('config.yml')
    @host = @config['host']
    @term = @config['term']
    @auth_token = @config['admin_token']
    @headers = {'Authorization' => "Bearer #{@auth_token}", 'Content-Type' => 'application/json'}
  end

  def filter(hsh, *keys)
    hsh.dup.tap do |h|
      keys.each { |k| h.delete(k) }
    end
  end

# iterate through canvas account statistics api
  def statistics(canvas_account_id)
    options = {
      :headers => @headers
    }

    account_stats_path = "#{@host}/api/v1/accounts/#{canvas_account_id}/analytics/terms/#{@term}/statistics"
    account_stats_result = self.class.get(account_stats_path, options)

# adding the course id to a hash with unused and hidden since they don't always exist in the feed
    h1 = {"canvas_account_id" => "#{canvas_account_id}"}

# merging my custom hash with the canvas feed
    h1.merge!(account_stats_result)
    account_stats_result.replace(h1)

    statistics = account_stats_result
    statistics

  end

# loading account ids using /api/v1/accounts/:account_id/sub_accounts
  def load_canvas_account_ids
    @accounts = []
    CSV.foreach('reports/' + @config['accounts_csv'], :headers => :first_row) do |account|
      @accounts << {'canvas_account_id' => account['canvas_account_id']}
    end
    puts "Accounts Loaded from CSV for processing: #{@accounts.inspect}\n\n\n"
    @accounts
  end

# Specifying the Headers
  def account_stats_report_file
    headers = [
      'canvas_account_id',
      'courses',
      'subaccounts',
      'teachers',
      'students',
      'discussion_topics',
      'media_objects',
      'attachments',
      'assignments'
    ]

    @account_stats_report_file = CSV.open('reports/' + @config['report_filename'], 'wb', { :headers => headers, :write_headers => true})
  end

# This is the Account Statistics Report that aggregates sub account statistics into one file
  def account_stats_report
    load_canvas_account_ids
    report_file = account_stats_report_file
    @accounts.each do |account|
      puts account['canvas_account_id']
      stats = statistics(account['canvas_account_id'])
      report_file << stats.values
    end
    puts "---------------------------"
    puts "Report Generation Completed"
    puts "---------------------------"
  end
end

proxy = Find_Account_Stats.new
proxy.account_stats_report

