# frozen_string_literal: true

require 'uri'
require 'net/https'
require 'json'

class ClockifyBot
  CLOCKIFY_EMAIL = 'youremail@test.com'
  CLOCKIFY_PASSWORD = 'yourpassword'
  PROJECT_NAME = 'projectname' # As it appears in clockify

  def run
    commits.each do |k, v|
      data = { start_date: "#{k}T03:30:00.000Z", end_date: "#{k}T11:30:00.000Z", description: v }
      update_clockify(data)
      sleep(1)
    end
  end

  private

  def commits
    @commits ||= begin
      from_date = ARGV[0]
      to_date = ARGV[1] || Time.now.strftime('%F')

      author = `git config user.name`
      commit_blocks = `git log --no-merges --author=#{author.strip} --branches --pretty="%ad %s" --date=short --since=#{from_date} --until=#{to_date}`
      commit_blocks
        .split("\n")
        .map { |c| c.strip.split(' ', 2) }
        .group_by { |c| c[0] }
        .transform_values { |v| v.map(&:last).join(', ') }
    end
  end

  def update_clockify(data)
    uri = URI("https://global.api.clockify.me/v1/workspaces/#{workspace_id}/user/#{user[:id]}/time-entries")
    body = {
      start: data[:start_date],
      billable: false,
      description: data[:description],
      projectId: '5d22e3711d234217a94b9652',
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
        email: CLOCKIFY_EMAIL,
        password: CLOCKIFY_PASSWORD
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

  def project_id
    @project_id ||= begin
      uri = URI("https://global.api.clockify.me/workspaces/#{workspace_id}/projects/user/#{user[:id]}/filter?page=1&search=@#{PROJECT_NAME}&include=ONLY_NOT_FAVORITES")
      res = get_request(uri)
      JSON.parse(res.body)[0]['id']
    end
  end

  def get_request(uri)
    sleep 1
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    req = Net::HTTP::Get.new(
      uri.path,
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
      uri.path,
      { 'Content-Type': 'application/json' }.tap do |headers|
        headers['x-auth-token'] = user[:token] unless auth_call
      end
    )
    req.body = body.to_json
    https.request(req).tap do |res|
      puts "POST Response ---> #{res.body}\n\n"
    end
  end
end

ClockifyBot.new.run
