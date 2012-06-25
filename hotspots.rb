require 'json'

require 'sinatra'
require 'haml'

require './repo'
require 'debugger'

$settings = {}
repos = {}

configure do
  $settings = JSON.parse(File.read 'settings.json')
  settings_repos = $settings['repos']

  settings_repos.each do |repo|
    repo = Repo.new(repo)
    repos[repo.org] ||= {}
    repos[repo.org][repo.name] = repo
  end

  repos.each do |org, org_repos|
    org_repos.each do |name, repo|
      repo.set_hooks
      repo.spots = repo.get_hotspots
    end
  end
end


post "/api/:org/:name" do
  begin
    data = JSON.parse request.body.read
    action = data['action']
    unless action == 'opened'
      return
    end
    org = params[:org]
    name = params[:name]
    repo = repos[org][name]
    sha = data['head']['sha']
    puts sha
    hotspots = repo.get_hotspots(sha: sha)
    puts hotspots
  rescue Exception => e
    puts e
  ensure
    status 204
  end
end


get "/hotspots/:org/:name/?:sha?" do |org, name, sha|
  repo = repos[org][name]
  spots = repo.get_hotspots('master', sha: sha)
  haml :hotspots, locals:{ :repo => repo, :spots => spots }
end

get '/' do
  haml :index, locals:{ :repos => repos }
end
