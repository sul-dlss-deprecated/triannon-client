require 'pry' # for debugging specs

require 'simplecov'
require 'coveralls'
SimpleCov.profiles.define 'triannon-client' do
  add_filter 'pkg'
  add_filter 'spec'
  add_filter 'vendor'
end
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start 'triannon-client'

# Ensure there are no ENV configuration values.
FileUtils.mv '.env', '.env_bak', force: true
config_keys = ENV.keys.select {|k| k =~ /TRIANNON/ }
config_keys.each {|k| ENV.delete k }
require 'triannon-client'
::TriannonClient.reset

require 'rspec'
RSpec.configure do |config|
  # config.fail_fast = true
end

require 'vcr'
cassette_ttl = 7 * 24 * 60 * 60  # 7 days, in seconds
VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = false
  c.default_cassette_options = {
    :record => :new_episodes,  # :once is default
    :re_record_interval => cassette_ttl
  }
  c.configure_rspec_metadata!
end

def triannon_config_no_auth
  begin
    triannon_reset
    ::TriannonClient.configure do |config|
      config.debug = false
      config.host = 'http://localhost:3000'
      config.client_id = ''
      config.client_pass = ''
      config.container = '/annotations/foo'
      config.container_user = ''
      config.container_workgroups = ''
    end
    true
  rescue
    false
  end
end

def triannon_config_auth
  begin
    triannon_reset
    ::TriannonClient.configure do |config|
      config.debug = false
      config.host = 'http://localhost:3000'
      config.client_id = 'clientA'
      config.client_pass = 'secretA'
      config.container = '/annotations/bar'
      config.container_user = ''
      config.container_workgroups = 'org:wg-A, org:wg-B'
    end
    true
  rescue
    false
  end
end

def triannon_reset
  config_keys = ENV.keys.select {|k| k =~ /TRIANNON/ }
  config_keys.each {|k| ENV.delete k }
  ::TriannonClient.reset
end

def create_client
  triannon_config_auth
  TriannonClient::TriannonClient.new
end

def clear_annotations(cassette='CRUD/clear_annotations')
  VCR.use_cassette(cassette) do
    client = create_client
    client.authenticate
    annos = client.get_annotations
    q = [nil, RDF.type, RDF::Vocab::OA.Annotation]
    anno_ids = annos.query(q).subjects.collect {|s| client.annotation_id(s)}
    anno_ids.each {|id| client.delete_annotation(id) }
  end
end

def create_annotation(cassette='CRUD/create_annotation')
  VCR.use_cassette(cassette) do
    client = create_client
    client.authenticate
    r = client.post_annotation(jsonld_oa)
    g = client.response2graph(r)
    uris = client.annotation_uris(g)
    id = client.annotation_id(uris.first)
    {
      response: r,
      graph: g,
      uris: uris,
      id: id
    }
  end
end

def delete_annotation(id, cassette='CRUD/delete_annotation')
  VCR.use_cassette(cassette) do
    client = create_client
    client.authenticate
    client.delete_annotation(id)
  end
end

def graph_is_empty(graph)
  expect(graph).to be_instance_of RDF::Graph
  expect(graph).to be_empty
end

def graph_contains_open_annotation(graph, uris)
  expect(graph).to be_instance_of RDF::Graph
  graph_contains_statements(graph)
  expect(uris).to be_instance_of Array
  expect(uris.first).to be_instance_of RDF::URI
  result = graph.query([nil, RDF.type, RDF::Vocab::OA.Annotation])
  expect(result.size).to be > 0
  intersection = result.subjects.to_a & uris
  expect(intersection).not_to be_empty
end

def graph_contains_statements(graph)
  expect(graph).to be_instance_of RDF::Graph
  expect(graph).not_to be_empty
  expect(graph.size).to be > 2
end

def jsonld_accept
  {:accept=>"application/ld+json"}
end

def jsonld_content
  {content_type: 'application/ld+json'}
end

def jsonld_oa
  @oa_jsonld ||= '{"@context":"http://iiif.io/api/presentation/2/context.json","@graph":[{"@id":"_:g70349699654640","@type":["dctypes:Text","cnt:ContentAsText"],"chars":"I love this!","format":"text/plain","language":"en"},{"@type":"oa:Annotation","motivation":"oa:commenting","on":"http://purl.stanford.edu/kq131cs7229","resource":"_:g70349699654640"}]}'
end
