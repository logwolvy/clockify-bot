# frozen_string_literal: true

require 'uri'
require 'net/https'
require 'json'
require 'yaml'

class ClockifyBot
  def initialize(config = YAML.load(File.read('./config.yml')))
    raise ArgumentError, 'Expects from_date to be provided' unless ARGV[0]

    @from_date = ARGV[0]
    @to_date = ARGV[1] || Time.now.strftime('%F')
    @config = config
  end

  def run
    config['PROJECTS'].each do |project|
      @project_id = fetch_project_id(project['name'])

      commits(project['local_paths']).each do |k, v|
        data = { start_date: "#{k}T03:30:00.000Z", end_date: "#{k}T11:30:00.000Z", description: v }
        update_clockify(data)
      end.tap { |c| puts "Commits for #{project['name']} -> #{c} \n\n" if ENV['DEBUG'] }
    end
  end

  private

  attr_reader :config, :from_date, :to_date, :project_id

  def commits(paths)
    commit_blocks = paths.map do |path|
      author = `git config user.name`
      service_name = path.split('/').last
      `cd #{path} && git log --branches --no-merges --author=#{author.strip} --pretty="%ad %s in #{service_name}" --date=short --since=#{from_date} --until=#{to_date}`
    end.join("\n")

    commit_blocks
      .split("\n")
      .map { |c| c.strip.split(' ', 2) }
      .uniq
      .reject { |c| c.empty? || ignorable_commit?(c[1]) }
      .group_by { |c| c[0] }
      .transform_values { |v| v.map(&:last).join(', ') }
  end

  def update_clockify(data)
    sleep 1
    uri = URI("https://global.api.clockify.me/v1/workspaces/#{workspace_id}/user/#{user[:id]}/time-entries")
    body = {
      start: data[:start_date],
      billable: false,
      description: data[:description],
      projectId: project_id,
      taskId: nil,
      end: data[:end_date],
      tagIds: []
    }
    post_request(uri, body)
  end

  def user
    @user ||= begin
      uri = URI('https://global.api.clockify.me/auth/token')
      body = {
        email: config['CLOCKIFY_EMAIL'],
        password: config['CLOCKIFY_PASSWORD']
      }
      res = post_request(uri, body, true)
      body = JSON.parse(res.body)
      { id: body['id'], token: body['token'] }
    end
  end

  def workspace_id
    @workspace_id ||= begin
      uri = URI("https://global.api.clockify.me/users/#{user[:id]}")
      res = get_request(uri)
      JSON.parse(res.body)['defaultWorkspace']
    end
  end

  def fetch_project_id(project_name)
    uri = URI("https://global.api.clockify.me/workspaces/#{workspace_id}/projects/user/#{user[:id]}/filter")
    params = { page: 1, search: "@#{project_name}", include: 'ONLY_NOT_FAVORITES' }
    uri.query = URI.encode_www_form(params)
    res = get_request(uri)
    JSON.parse(res.body)[0]['id']
  end

  def get_request(uri)
    sleep 1
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Get.new(
      uri,
      { 'Content-Type': 'application/json' }.tap do |headers|
        headers['x-auth-token'] = user[:token]
      end
    )
    https.request(req).tap do |res|
      puts "GET response --> #{res.body}\n\n"
    end
  end

  def post_request(uri, body, auth_call = false)
    sleep 1
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(
      uri,
      { 'Content-Type': 'application/json' }.tap do |headers|
        headers['x-auth-token'] = user[:token] unless auth_call
      end
    )
    req.body = body.to_json
    https.request(req).tap do |res|
      puts "POST Response ---> #{res.body}\n\n"
    end
  end

  def ignorable_commit?(commit_msg)
    %w[Revert Squashed].map { |w| commit_msg.include?(w) }.include?(true)
  end
end

ClockifyBot.new.run
