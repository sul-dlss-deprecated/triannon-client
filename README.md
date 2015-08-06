[![Build Status](https://travis-ci.org/sul-dlss/triannon-client.svg?branch=master)](https://travis-ci.org/sul-dlss/triannon-client) [![Coverage Status](https://coveralls.io/repos/sul-dlss/triannon-client/badge.png)](https://coveralls.io/r/sul-dlss/triannon-client) [![Dependency Status](https://gemnasium.com/sul-dlss/triannon-client.svg)](https://gemnasium.com/sul-dlss/triannon-client) [![Gem Version](https://badge.fury.io/rb/triannon-client.svg)](http://badge.fury.io/rb/triannon-client)


# Under construction!

Any gem released prior to 1.x may have an unstable API.  As the triannon server and this client are in rapid development (as of 2015), expect new gem releases that could break the API.


# Triannon Client

A client for the triannon service, see also
- https://github.com/sul-dlss/triannon
- https://github.com/sul-dlss/triannon-service


## Installation into ruby projects

```ruby
gem 'triannon-client'
```

Then execute:

```sh
bundle
```


## Using the client

### Configuration

Edit a `.env` file to configure the triannon server address etc.
(see .env_example); or use a configure block.  The configuration
for authentication depends on prior triannon server configuration, see
 - https://github.com/sul-dlss/triannon#configuration

This example configuration may work with a triannon server running
on localhost in the development environment (see below for details).

```ruby
require 'triannon-client'
::TriannonClient.reset
::TriannonClient.configure do |config|
  config.debug = false
  config.host = 'http://localhost:3000'
  config.client_id = 'clientA'
  config.client_pass = 'secretA'
  config.container = '/annotations/bar'
  config.container_user = ''
  config.container_workgroups = 'org:wg-A, org:wg-B'
end
```

### Get a client instance

A new instance is initialized using the configuration parameters (see above).

```ruby
tc = TriannonClient::TriannonClient.new
```

### Get a list of annotations

```ruby
# return an RDF::Graph
graph = tc.get_annotations
anno_uris = tc.annotation_uris(graph)
anno_ids = anno_uris.map {|uri| tc.annotation_id(uri) }
```

### Get a particular annotation

```ruby
# the default response is an open annotation in an RDF::Graph
oa_anno = tc.get_annotation(id)
```

For specific response formats, specify an HTTP `Accept` header, e.g.

```ruby
# explicitly request jsonld with an open annotation or a IIIF context
anno_oa   = tc.get_annotation(id, `application/ld+json; profile="http://www.w3.org/ns/oa-context-20130208.json"`)
anno_iiif = tc.get_annotation(id, `application/ld+json; profile="http://iiif.io/api/presentation/2/context.json"`)
# convenience methods to do the above
anno_oa   = tc.get_oa_annotation(id)
anno_iiif = tc.get_iiif_annotation(id)
```

### Create an annotation

```ruby
tc.post_annotation(open_annotation_jsonld)
```

### Delete an annotation

```ruby
uri = RDF::URI.new("http://your.triannon-server.com/annotations/45/4a/c0/93/454ac093-b37d-4580-bebd-449f8dabddc9")
id = tc.annotation_id(uri) #=> "45%2F4a%2Fc0%2F93%2F454ac093-b37d-4580-bebd-449f8dabddc9"
tc.delete_annotation(id)
```

Note: the annotation URI contains a pair-tree path (created by a Fedora 4 repository for triannon annotations).  The annotation ID is the entire pair-tree path, after a URI escape. The URI escape makes it easier to work with the ID for `tc.get_annotation(id)` and `tc.delete_annotation(id)`.  For more information on object storage using pair-trees, see
  - http://www.slideshare.net/jakkbl/dcc-pair-posterppt
  - https://wiki.ucop.edu/display/Curation/PairTree

## Development

#### Clone and install:

```sh
git clone https://github.com/sul-dlss/triannon-client.git
cd triannon-client
./bin/setup.sh  # runs bundle install
```

#### Run tests:

```sh
rake
```

The server request/response cycle has been recorded in `spec/fixtures/vcr_cassettes` (see http://www.relishapp.com/vcr).

#### Tests with live server interactions

- Startup a triannon server running on localhost in the development environment (the `spec/spec_helper.rb` is configured to interact with this server). For details on running triannon in development, see
  - https://gist.github.com/darrenleeweber/bcfc9698ce5f5af8f465 
  - https://github.com/sul-dlss/triannon#running-this-code-in-development 

```sh
git clone https://github.com/sul-dlss/triannon.git
git clone https://gist.github.com/bcfc9698ce5f5af8f465.git triannon_reset
cp ./triannon_reset/triannon_server_reset.sh triannon/bin/
cd triannon
./bin/triannon_server_reset.sh
# GO GET A TASTY BEVERAGE ;-)
```

- Run the triannon client specs against the localhost server.
```sh
git clone https://github.com/sul-dlss/triannon-client.git
cd triannon-client
./bin/setup.sh  # bundle update and package
rm -rf spec/fixtures/vcr_cassettes
rake
```
